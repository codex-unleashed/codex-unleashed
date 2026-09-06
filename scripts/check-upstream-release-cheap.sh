#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
upstream_repo="${1:-openai/codex}"
release_json="$(GITHUB_TOKEN="${GITHUB_TOKEN:-}" "${repo_root}/scripts/check-upstream-release.sh" "${upstream_repo}")"
upstream_tag="$(jq -er '.tag_name' <<<"${release_json}")"
upstream_sha="$(jq -er '.target_commitish' <<<"${release_json}")"

if [[ "$(jq -er '(.draft or .prerelease)' <<<"${release_json}")" == "true" ]]; then
  echo "Latest upstream release ${upstream_tag} is a prerelease or draft; nothing to verify."
  exit 0
fi

echo "Checking upstream release ${upstream_tag} (${upstream_sha})."
temp_root="$(mktemp -d)"
trap 'rm -rf "${temp_root}"' EXIT
upstream_checkout="${temp_root}/upstream"

git -c protocol.version=2 clone --filter=blob:none --no-checkout --depth 1 \
  --branch "${upstream_tag}" "https://github.com/${upstream_repo}.git" "${upstream_checkout}"
git -C "${upstream_checkout}" checkout --detach "${upstream_tag}" >/dev/null
"${repo_root}/scripts/apply-patches.sh" "${upstream_checkout}"
git -C "${upstream_checkout}" diff --check

pushd "${upstream_checkout}" >/dev/null
export CODEX_REPO_ROOT="${upstream_checkout}"
ALLOW_STALE_CODE_MODE_FEATURE_EXCEPTION=1 python3 - "${repo_root}" "${upstream_checkout}" <<'PY'
import runpy
import sys
from pathlib import Path

repo_root = Path(sys.argv[1])
upstream_root = Path(sys.argv[2])


def run_check(relative_path, replacements):
    namespace = runpy.run_path(str(repo_root / relative_path))
    namespace["main"].__globals__.update(replacements)
    original_argv = sys.argv
    sys.argv = [relative_path]
    try:
        return namespace["main"]()
    finally:
        sys.argv = original_argv


checks = (
    (
        ".github/scripts/verify_cargo_workspace_manifests.py",
        {"ROOT": upstream_root, "CARGO_RS_ROOT": upstream_root / "codex-rs"},
    ),
    (
        ".github/scripts/verify_tui_core_boundary.py",
        {
            "ROOT": upstream_root,
            "TUI_ROOT": upstream_root / "codex-rs" / "tui",
            "TUI_MANIFEST": upstream_root / "codex-rs" / "tui" / "Cargo.toml",
        },
    ),
    (
        ".github/scripts/verify_bazel_clippy_lints.py",
        {
            "ROOT": upstream_root,
            "DEFAULT_CARGO_TOML": upstream_root / "codex-rs" / "Cargo.toml",
            "DEFAULT_BAZELRC": upstream_root / ".bazelrc",
        },
    ),
)
for path, replacements in checks:
    if run_check(path, replacements):
        raise SystemExit(1)
PY
popd >/dev/null

expected_assets=()
targets=(
  x86_64-unknown-linux-musl
  aarch64-unknown-linux-musl
  x86_64-apple-darwin
  aarch64-apple-darwin
  x86_64-pc-windows-msvc
  aarch64-pc-windows-msvc
)
for target in "${targets[@]}"; do
  expected_assets+=("codex-package-${target}.tar.gz")
  expected_assets+=("codex-app-server-package-${target}.tar.gz")
  if [[ "${target}" == *windows* ]]; then
    expected_assets+=("codex-windows-sandbox-setup-${target}.exe.tar.gz")
  fi
done

upstream_assets="$(jq -r '.assets[].name' <<<"${release_json}")"
for asset in "${expected_assets[@]}"; do
  if ! grep -Fxq "${asset}" <<<"${upstream_assets}"; then
    echo "ERROR: upstream release ${upstream_tag} is missing ${asset}." >&2
    exit 1
  fi
done

check_resource_manifest() {
  local manifest="$1"
  local release_repo="$2"
  local release_tag="$3"
  local release_json
  release_json="$(gh api "repos/${release_repo}/releases/tags/${release_tag}")"

  while IFS=$'\t' read -r name size digest; do
    [[ -n "${name}" ]] || continue
    local actual_size actual_digest
    actual_size="$(jq -er --arg name "${name}" '.assets[] | select(.name == $name) | .size' <<<"${release_json}")"
    actual_digest="$(jq -er --arg name "${name}" '.assets[] | select(.name == $name) | .digest' <<<"${release_json}")"
    if [[ "${size}" != "${actual_size}" || "sha256:${digest}" != "${actual_digest}" ]]; then
      echo "ERROR: ${manifest} disagrees with ${release_repo}@${release_tag} asset ${name}." >&2
      echo "       manifest: size=${size} digest=sha256:${digest}" >&2
      echo "       upstream: size=${actual_size} digest=${actual_digest}" >&2
      exit 1
    fi
  done < <(python3 - "${repo_root}/${manifest}" <<'PY'
import json
import sys
from pathlib import Path
from urllib.parse import urlparse

data = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8").split("\n", 1)[1])
for platform in data["platforms"].values():
    provider = next(
        item for item in platform["providers"]
        if item.get("type") == "github-release" or "url" in item
    )
    if "url" in provider:
        name = Path(urlparse(provider["url"]).path).name
    else:
        name = provider["name"]
    print(name, platform["size"], platform["digest"], sep="\t")
PY
  )
}

check_resource_manifest scripts/codex_package/codex-zsh openai/codex codex-zsh-v0.1.0
check_resource_manifest scripts/codex_package/rg BurntSushi/ripgrep 15.2.0

echo "Cheap upstream release check passed for ${upstream_tag}. No compilation was performed."

if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
  needs_full="false"
  if [[ "${GITHUB_EVENT_NAME:-}" == "schedule" ]]; then
    existing_release="false"
    while IFS= read -r release_tag; do
      if [[ "${release_tag}" == "${upstream_tag}+"* ]]; then
        existing_release="true"
        break
      fi
    done < <(gh api --paginate "repos/${GITHUB_REPOSITORY}/releases?per_page=100" --jq '.[] | .tag_name')
    if [[ "${existing_release}" != "true" ]]; then
    needs_full="true"
    fi
  fi
  echo "upstream_tag=${upstream_tag}" >> "${GITHUB_OUTPUT}"
  echo "needs_full=${needs_full}" >> "${GITHUB_OUTPUT}"
fi

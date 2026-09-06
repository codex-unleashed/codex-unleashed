#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: apply-patches.sh <upstream-checkout>

Applies every patch under patches/**/ to the target checkout.
Fails immediately if any patch does not apply.
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

if [[ $# -ne 1 ]]; then
  usage >&2
  exit 1
fi

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
target_dir="$(cd "${1}" && pwd)"
patch_dir="${repo_root}/patches"

if [[ ! -d "${target_dir}/.git" ]]; then
  echo "ERROR: target is not a git checkout: ${target_dir}" >&2
  exit 1
fi

patches=()
while IFS= read -r patch_file; do
  patches+=("${patch_file}")
done < <(find "${patch_dir}" -type f -name '*.patch' | sort)

if [[ ${#patches[@]} -eq 0 ]]; then
  echo "No patch files found in ${patch_dir}; nothing to apply."
  exit 0
fi

for patch_file in "${patches[@]}"; do
  echo "Applying ${patch_file#${repo_root}/}"
  if LC_ALL=C grep -q $'\r' "${patch_file}"; then
    echo "ERROR: patch is not LF-normalized: ${patch_file#${repo_root}/}" >&2
    exit 1
  fi
  # CI checkouts are shallow and do not need to create commits from patch files.
  git -C "${target_dir}" apply "${patch_file}"
done

#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "Usage: $0 <package-directory> [registry]" >&2
}

if [[ "$#" -lt 1 || "$#" -gt 2 ]]; then
  usage
  exit 2
fi

package_dir="$1"
registry="${2:-http://127.0.0.1:4873}"
test_dir="$(mktemp -d "${TMPDIR:-/tmp}/codex-npm-install.XXXXXX")"
trap 'rm -rf "$test_dir"' EXIT

npm init --yes --scope codex-unleashed --prefix "$test_dir" >/dev/null
package_tarball="$(npm pack "$package_dir" --pack-destination "$test_dir" --silent)"
npm install --prefix "$test_dir" --registry "$registry" "$test_dir/$package_tarball"
npm exec --prefix "$test_dir" -- codex --version
echo "Local npm installation smoke test passed."

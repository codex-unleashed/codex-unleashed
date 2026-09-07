#!/usr/bin/env bash

set -euo pipefail

usage() {
  echo "usage: $0 <pull|push|prune> <repository> <tag> <target-directory> <upstream-tag>" >&2
  exit 2
}

[[ $# -eq 5 ]] || usage

operation="$1"
repository="$2"
tag="$3"
target_directory="$4"
upstream_tag="$5"
reference="${repository}:${tag}"

prune_old_tags() {
  # The cache repository is dedicated to Cargo targets. Keep only entries
  # for the current upstream release; old upstream versions are no longer
  # useful because every target cache key includes the upstream tag.
  while IFS= read -r existing_tag; do
    [[ -n "$existing_tag" ]] || continue
    [[ "$existing_tag" == cargo-* ]] || continue
    [[ "$existing_tag" == *"-${upstream_tag}" ]] && continue
    oras manifest delete "${repository}:${existing_tag}" --force
  done < <(oras repo tags "$repository")
}

case "$operation" in
  pull)
    mkdir -p "$target_directory"
    archive_directory="$(mktemp -d "${RUNNER_TEMP:-/tmp}/codex-ghcr-cache.XXXXXX")"
    trap 'rm -rf "$archive_directory"' EXIT
    oras pull "$reference" --output "$archive_directory"
    tar --zstd -xf "$archive_directory/cargo-target.tar.zst" -C "$target_directory"
    ;;
  push)
    [[ -d "$target_directory" ]] || {
      echo "Cargo target directory does not exist: $target_directory" >&2
      exit 1
    }
    archive_directory="$(mktemp -d "${RUNNER_TEMP:-/tmp}/codex-ghcr-cache.XXXXXX")"
    trap 'rm -rf "$archive_directory"' EXIT
    archive="$archive_directory/cargo-target.tar.zst"
    tar --zstd -cf "$archive" -C "$target_directory" .
    oras push "$reference" \
      --artifact-type application/vnd.codex-unleashed.cargo-target.v1 \
      "$archive:application/vnd.codex-unleashed.cargo-target.tar+zstd"

    prune_old_tags
    ;;
  prune)
    prune_old_tags
    ;;
  *)
    usage
    ;;
esac

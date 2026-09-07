# Release build cache

Release builds use the GitHub Actions cache for normal dependency and target
reuse. The release workflow also has an opt-in GHCR overflow cache for the
largest pruned Cargo target trees:

```text
ghcr.io/codex-unleashed/codex-unleashed-cargo-cache:cargo-<target>-<upstream-tag>
```

The cache contains only the post-build Cargo target directory after release
archives, debug symbols, staging directories, and timing files have been
removed. It does not contain release packages or credentials.

Enable it with `ghcr_cache: true` when dispatching `rust-release.yml` or when
calling `release-build.yml`. The repository package must be configured as a
public container package if the cache is intended to remain within GitHub's
free public-package policy. Cache contents are therefore public and must not
contain secrets.

Each cache tag includes the upstream tag. After a cache is populated, the
workflow removes older `cargo-*` tags from this dedicated package, retaining
only caches for the current upstream release.

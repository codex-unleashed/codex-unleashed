# Release build cache

Release builds use the GitHub Actions cache for normal dependency and target
reuse. Because the platform target caches exceed GitHub's default repository
cache quota, the release workflow also uses a GHCR overflow cache for the
largest pruned Cargo target trees:

```text
ghcr.io/codex-unleashed/cargo-cache:cargo-<target>-<upstream-tag>
```

The cache contains only the post-build Cargo target directory after release
archives, debug symbols, staging directories, and timing files have been
removed. It does not contain release packages or credentials.

The repository package must be configured as a public container package to
remain within GitHub's free public-package policy. Cache contents are
therefore public and must not contain secrets. Set `ghcr_cache: false` only
for cache diagnostics or while configuring the package.

Each cache tag includes the upstream tag. After a cache is populated, the
workflow removes older `cargo-*` tags from this dedicated package, retaining
only caches for the current upstream release.

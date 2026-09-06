# Codex Unleashed branding and build metadata

This distribution patch adds Codex Unleashed build metadata to the CLI and
interactive session header. The upstream version remains visible as the base
version, with the provider build appended as SemVer build metadata.

The build number is supplied at compile time through
`CODEX_UNLEASHED_BUILD_NUMBER` by the release workflow.

## `--version`

```text
codex-cli 0.153.4+25
(See --build-info for more information)
```

## `--build-info`

```text
vendor: codex-unleashed
vendor_url: https://github.com/codex-unleashed/codex-unleashed
upstream_url: https://github.com/openai/codex
upstream_version: 0.153.4
build: 25
```

The interactive session header shows `v0.153.4+25` and the provider website
`https://codex-unleashed.com/` beneath it, aligned with the title text.

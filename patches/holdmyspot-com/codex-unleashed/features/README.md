# Codex Unleashed features

This distribution patch registers downstream features in Codex's feature
registry. Feature names use the `unleashed_` prefix to avoid conflicts with
upstream names.

For issue #34776:

```text
unleashed_agent_fast_switching  stable  true
```

The feature is enabled by default and can be controlled with:

```text
codex features enable unleashed_agent_fast_switching
codex features disable unleashed_agent_fast_switching
```

This directory vendors the upstream `openai/codex` GitHub Actions baseline.

Contents:
- `.github/workflows/`
- `.github/actions/`
- `.github/scripts/`

Purpose:
- Keep an exact upstream reference snapshot in this repository.
- Make local workflow drift easy to review.
- Let `codex-unleashed` start from upstream CI/release definitions and apply only patch-layer changes where required.

Refresh command:
```bash
./scripts/sync-upstream-github.sh
```

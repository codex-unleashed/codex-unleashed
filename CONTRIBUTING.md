# Contributing

This repository does not accept pull requests.

## Why

`codex-unleashed` is intended to remain a narrowly-scoped public patch queue for reviewed Codex fixes and features, not a general fork.

## What To Do Instead

- If you need your own changes, fork this repository privately or publicly and maintain your own patch queue.
- If you want a bug fixed here, open an issue request or a quote request.
- If you need private or commercial engineering work, contact the maintainer for a quote.

## Patch Policy

- Every issue directory must correspond to one repository-relative reviewed issue.
- Every patch must contain exactly one logical bug fix.
- Fixes follow test-driven development: include a regression test that fails before the fix and passes after it.
- Tests must follow the surrounding upstream test style, including naming, structure, helper usage, formatting, and assertion patterns.
- Patches should be generated with `git format-patch`.
- Patches should remain small, auditable, and removable after upstream fixes the issue.

## Funding / Contact

- GitHub: `@cowwoc`
- Email: `cowwoc2020@gmail.com`
- Paddle: `TODO_PADDLE_URL`

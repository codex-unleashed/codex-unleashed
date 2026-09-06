# Codex Unleashed

A public patch queue and patched binary distribution for OpenAI Codex.

> Warning: Unofficial, not affiliated with OpenAI.

[![License](https://img.shields.io/github/license/codex-unleashed/codex-unleashed)](https://github.com/codex-unleashed/codex-unleashed/blob/main/LICENSE)
[![Public patches](https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/codex-unleashed/codex-unleashed/main/docs/badges/public-patches.json)](https://github.com/codex-unleashed/codex-unleashed/tree/main/patches)
[![Early-access patches](https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/codex-unleashed/codex-unleashed/main/docs/badges/early-access.json)](https://codex-unleashed.com/)

**[Get early access to Codex fixes and features →](https://codex-unleashed.com/)**

## Quickstart

### Download a public patched release

Open the latest [GitHub Release](https://github.com/codex-unleashed/codex-unleashed/releases/latest) and download the archive for your platform.

The exact filenames follow the published release artifacts for the current upstream build targets. In practice, pick the artifact matching your OS and architecture.

After extracting the archive, run the included `codex` binary the same way you would run upstream Codex.

## Get A Fix Faster

- Public release: use the latest [GitHub Release](https://github.com/codex-unleashed/codex-unleashed/releases/latest).
- Priority access: subscribers receive priority consideration for requested fixes and early access to completed patched builds.
- New fix request: open an issue and describe the bug, scope, and business impact.
- Quote request: contact the maintainer directly for private or larger commercial work.

## Why This Exists

- Important user-facing issues can take months to be fixed upstream, even when they are time-sensitive for real users and teams.
- This project bridges that gap by shipping small, targeted fixes for issues that matter to users now, not months later.
- Patches stay public, auditable, and temporary: they are carried here until the equivalent fix lands upstream, then removed.
- Subscribers get priority consideration for requested fixes and early access to completed patched builds before those fixes roll into the public release.

## What To Expect

- Reviewed fixes only.
- No pull requests.
- No unpaid support queue.

## Early Access Policy

Subscribers pay US$12 per named developer per month, month-to-month, for priority consideration of requested fixes and early access to completed patched builds.

- A request does not guarantee that a fix will be implemented, or establish a delivery date.
- You only pay for months when early-release fixes are available. No fixes? Your subscription will be credited.
- Early-release fixes become eligible for public release at least 30 days after first customer delivery. Fixes that require substantial investment may remain in early access longer.
- Full terms: [Commercial Terms](docs/COMMERCIAL_TERMS.md)

Paddle: `TODO_PADDLE_URL`

## How Releases Work

For every upstream Codex release, this repository publishes a corresponding patched release after applying the active patch queue, running the relevant checks, and rebuilding release artifacts.

Every release notes page lists:

- Upstream Codex version/tag
- Patch files applied
- Upstream commit SHA
- Build date
- Supported platforms
- Checksums

## Versioning

Patched releases add a vendor build number to the upstream version:

- Upstream `1.3.6` -> patched `1.3.6+25`

The `+25` suffix identifies the vendor build. Build numbers are assigned by the release workflow and distinguish later patched builds based on the same upstream version.

## Policies

- Commercial terms: [docs/COMMERCIAL_TERMS.md](docs/COMMERCIAL_TERMS.md)
- Support policy: [SUPPORT.md](SUPPORT.md)
- Security policy: [SECURITY.md](SECURITY.md)
- Patch queue rules: [patches/README.md](patches/README.md)

## License

This project uses the same license as upstream Codex. See [LICENSE](LICENSE).

## Contact

- GitHub: [@cowwoc](https://github.com/cowwoc)
- Email: `cowwoc2020@gmail.com`
- Paddle: `TODO_PADDLE_URL`

# Changelog

All notable changes to this project are documented here.

## [1.0.0] - 2026-07-23

Initial public release.

### Added

- A loopback-only SSH client for the Pravelle matcher and prover ports.
- Explicit tester identity-file and permission checks.
- Rejection of inherited local, remote, or dynamic SSH forwards.
- SSH hardening that disables shell and TTY allocation, agent and X11
  forwarding, connection multiplexing, password authentication, and local
  commands.
- English and Simplified Chinese documentation.
- Offline safety tests, source checksums, and a private vulnerability-reporting
  policy.

[1.0.0]: https://github.com/cysic-labs/pravelle-tester-tunnel/releases/tag/v1.0.0

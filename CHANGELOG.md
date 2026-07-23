# Changelog

All notable changes to this project are documented here.

## [1.0.1] - 2026-07-23

### Security

- Refuse unknown or changed SSH host keys instead of allowing a first-contact
  trust prompt.
- Disable opportunistic host-key replacement and DNS-based host-key lookup.

### Documentation

- Define the tester-generated key handoff: the tester sends only the public
  `.pub` file and keeps the private key local.
- Require the operator to deliver the exact SSH host fingerprint through an
  independent approved channel.
- Add commands for port preflight and fingerprint verification.

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
[1.0.1]: https://github.com/cysic-labs/pravelle-tester-tunnel/releases/tag/v1.0.1

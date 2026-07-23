# Security Policy

## Supported versions

Only the latest tagged release is supported.

## Reporting a vulnerability

Use the hosting repository's private vulnerability-reporting feature. Do not
open a public issue containing credentials, real infrastructure details, or an
unpatched vulnerability.

Include:

- the affected version and operating system;
- the exact command and sanitized output;
- the expected and observed behavior;
- a minimal reproduction that contains no real key, hostname, or address.

Revoke any exposed tester key immediately through the private operator channel.

The operator must provide a named private escalation channel to every testing
cohort. If private vulnerability reporting is unavailable, stop testing and use
that operator channel; never fall back to a public issue for a live credential,
hostname, fingerprint mismatch, or unpatched vulnerability.

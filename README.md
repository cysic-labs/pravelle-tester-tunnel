# Pravelle Tester Tunnel

A small, auditable SSH client for opening the two loopback-only forwards needed
by an authorized Pravelle test participant.

This repository is intentionally limited to the client-side tunnel. It does not
contain Pravelle contracts, prover or matcher code, deployment addresses,
credentials, server configuration, or production operations.

## What it opens

| Local endpoint | Remote endpoint | Intended service |
| --- | --- | --- |
| `127.0.0.1:8798` | `127.0.0.1:8798` | Matcher API |
| `127.0.0.1:8799` | `127.0.0.1:8802` | Prover API |

Both listeners bind to local loopback only. They are not exposed to the
participant's LAN.

## Requirements

- macOS or Linux
- Bash
- OpenSSH client
- A dedicated tester identity file
- A restricted SSH host alias supplied by the operator

The remote account must be restricted server-side with a forced command or no
shell, disabled agent/X11/TTY forwarding, and a `PermitOpen` allowlist for only
the two loopback services above. This client cannot enforce server policy.

## Use

```bash
chmod 600 /path/to/tester_identity
./bin/pravelle-tester-tunnel restricted-test-host /path/to/tester_identity
```

Keep the process running during the authorized test window. Stop it with
`Ctrl-C`.

The client deliberately:

- requires an explicit identity file;
- rejects identity files with permissions other than `0400` or `0600`;
- rejects SSH aliases that already define local, remote, or dynamic forwards;
- disables shell and TTY allocation, agent/X11 forwarding, multiplexing,
  password authentication, and local commands;
- fails if either requested local forward cannot be opened.

## Example SSH alias

Use values supplied by the operator. Do not commit real hostnames, usernames,
or key paths.

```sshconfig
Host restricted-test-host
    HostName example.invalid
    User restricted-tester
```

Do not put `LocalForward`, `RemoteForward`, or `DynamicForward` directives in
this alias. The client defines the complete forwarding set.

## Verify the release

From the release directory:

```bash
shasum -a 256 -c SHA256SUMS
./tests/test.sh
```

On Linux, `sha256sum -c SHA256SUMS` is equivalent.

## Security boundaries

This tool does not grant access by itself. It needs a separately issued,
time-bounded tester key and a server account configured by the operator.

Never:

- use an owner, deployer, operator, or Safe signer key;
- send a private key in chat, email, issue trackers, or screenshots;
- commit a real identity file or SSH host configuration;
- continue if the SSH account unexpectedly opens a remote shell.

If a shell opens, disconnect immediately and report the configuration problem
privately to the operator.

## Development

The test suite uses a local mock and makes no network connection:

```bash
./tests/test.sh
```

## License

MIT. The rights holder must approve the copyright and license before the first
public release.

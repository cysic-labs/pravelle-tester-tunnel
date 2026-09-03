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
| `127.0.0.1:8799` | `127.0.0.1:8805` | Prover API (override with `PRAVELLE_PROVER_PORT`) |

Both listeners bind to local loopback only. They are not exposed to the
participant's LAN.

## Requirements

- macOS or Linux
- Bash
- OpenSSH client
- A dedicated tester identity file generated and kept by the tester
- A restricted SSH host alias and SHA256 host-key fingerprint supplied by the
  operator through an approved private channel

The remote account must be restricted server-side with a forced command or no
shell, disabled agent/X11/TTY forwarding, and a `PermitOpen` allowlist for only
the two loopback services above. This client cannot enforce server policy.

## One-time tester onboarding

Generate a new, passphrase-protected key for this test. Do not reuse a wallet,
Safe signer, deployer, operator, or personal server key:

```bash
ssh-keygen -t ed25519 -a 64 -f ~/.ssh/pravelle-tester -C "pravelle-bsc-testnet"
chmod 600 ~/.ssh/pravelle-tester
```

Send only `~/.ssh/pravelle-tester.pub` to the operator. The file without
`.pub` is the private key and must remain on the tester's machine. The operator
installs the public key and privately returns:

1. the restricted SSH alias and its exact `HostName`, `User`, and optional
   `Port`;
2. the expected SHA256 host-key fingerprint, such as
   `SHA256:REPLACE_WITH_OPERATOR_VALUE`; and
3. the key activation and revocation times.

Before the first tunnel connection, collect the advertised host key and compare
its fingerprint with the independently delivered operator value:

```bash
ssh-keyscan -t ed25519 PASTE_RESTRICTED_HOSTNAME > /tmp/pravelle-host-key
ssh-keygen -lf /tmp/pravelle-host-key
```

For a non-default port, add `-p PASTE_PORT` to `ssh-keyscan`. If and only if the
displayed SHA256 fingerprint exactly matches, install the key:

```bash
mkdir -p ~/.ssh
chmod 700 ~/.ssh
ssh-keygen -H -f /tmp/pravelle-host-key
grep -v '^#' /tmp/pravelle-host-key >> ~/.ssh/known_hosts
chmod 600 ~/.ssh/known_hosts
```

Delete `/tmp/pravelle-host-key` afterward. If the alias uses a jump host, repeat
the out-of-band fingerprint check for both the jump host and the final host.
Never accept an unknown or changed host key merely to continue testing.

## Use

```bash
chmod 600 ~/.ssh/pravelle-tester
./bin/pravelle-tester-tunnel restricted-test-host ~/.ssh/pravelle-tester
```

Keep the process running during the authorized test window. Stop it with
`Ctrl-C`.

The client deliberately:

- requires an explicit identity file;
- rejects identity files with permissions other than `0400` or `0600`;
- refuses unknown or changed SSH host keys;
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
    IdentityFile ~/.ssh/pravelle-tester
    IdentitiesOnly yes
```

Do not put `LocalForward`, `RemoteForward`, or `DynamicForward` directives in
this alias. The client defines the complete forwarding set. The operator must
replace `example.invalid` with the privately supplied host; it is not a usable
server address.

Before starting the tunnel, confirm its ports are free:

```bash
# macOS
lsof -nP -iTCP:8798 -sTCP:LISTEN
lsof -nP -iTCP:8799 -sTCP:LISTEN

# Linux
ss -ltn '( sport = :8798 or sport = :8799 )'
```

No output means the ports are free. Do not kill an unfamiliar process; stop and
ask the operator if either port is already occupied.

## Verify the release

The current release is
[`v1.0.1`](https://github.com/cysic-labs/pravelle-tester-tunnel/releases/tag/v1.0.1).
Download both the source archive and `SHA256SUMS`, then verify the archive before
extracting it:

```bash
shasum -a 256 -c SHA256SUMS
tar -xzf pravelle-tester-tunnel-v1.0.1.tar.gz
cd pravelle-tester-tunnel-v1.0.1
```

From the extracted release directory, verify the tracked files and run the
offline test suite:

```bash
shasum -a 256 -c SHA256SUMS
./tests/test.sh
```

On Linux, `sha256sum -c SHA256SUMS` is equivalent.

## Security boundaries

This tool does not grant access by itself. It needs a tester-generated key whose
public half has been authorized for a limited window, plus a server account
configured by the operator.

Never:

- use an owner, deployer, operator, or Safe signer key;
- send a private key in chat, email, issue trackers, or screenshots;
- accept an SSH fingerprint that does not exactly match the operator handoff;
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

MIT. See [LICENSE](LICENSE).

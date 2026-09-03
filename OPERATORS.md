# Issuing tester credentials

For the operator running a testing cohort. Testers read [README.md](README.md);
nothing here is needed to use the tool.

Each tester gets three things: an SSH key restricted to two port forwards, the
prover token, and the host to point at. The first is per-tester and revocable on
its own; the other two are shared until the prover supports per-tester tokens.

## 1. The tester generates a key and sends you the public half

Have them run this and send you `pravelle-tester.pub` only:

```sh
ssh-keygen -t ed25519 -N '' -f ~/.ssh/pravelle-tester -C 'pravelle-tester-<name>'
chmod 600 ~/.ssh/pravelle-tester
```

The private half never leaves their machine. A key you generate and mail is a
key that existed in a mailbox.

## 2. Authorize it, restricted to the two forwards

Append one line to the tunnel account's `authorized_keys`:

```
restrict,port-forwarding,permitopen="127.0.0.1:8805",permitopen="127.0.0.1:8798",from="<tester IP>" ssh-ed25519 AAAA... pravelle-tester-<name>
```

Each option earns its place:

| option | why |
|---|---|
| `restrict` | refuses everything — shell, agent, X11, TTY, port forwarding |
| `port-forwarding` | adds forwarding back; **`restrict` disabled it** |
| `permitopen` ×2 | forwarding is limited to those two destinations |
| `from` | the key only works from that address |

**`restrict` implies `no-port-forwarding`.** Without `port-forwarding` added
back, the tunnel connects and then fails with `administratively prohibited:
open failed` — the connection succeeds, so it reads as a server problem rather
than a key option.

Verify from the tester's side before handing it over:

```sh
ssh -i ~/.ssh/pravelle-tester <host> true          # must fail: no shell
./bin/pravelle-tester-tunnel <host> ~/.ssh/pravelle-tester   # must open both forwards
```

The first failing is the point. If it opens a shell, the key is not restricted.

## 3. Ports

`8805` is the prover that implements `/attest`, the identity challenge the app
runs before it sends a token or a witness. `8798` is the matcher. If your
deployment uses different ports, set them in the `permitopen` options above and
tell the tester to pass `PRAVELLE_PROVER_PORT` / `PRAVELLE_MATCHER_PORT`.

A prover without `/attest` answers `404` there, and the tester sees "the prover
did not answer the identity challenge" — a message that points at the prover and
not at the port. Check the port answers before issuing:

```sh
curl -s -o /dev/null -w '%{http_code}\n' 'http://127.0.0.1:8805/attest?nonce=1'
```

## 4. The prover token

Send it over a channel that is not the issue tracker and not a group chat.

**It is currently shared across testers.** The prover compares against a single
`CYSIC_PROVER_TOKEN`, so there is no per-tester token to revoke and no way to
tell from prover logs which tester made a request. Until that changes:

- revoke through SSH — remove the tester's `authorized_keys` line, which cuts
  their access whatever token they hold;
- rotating the token invalidates it for **every** tester at once, so treat a
  suspected leak as a cohort-wide event;
- attribute through the SSH log, not the prover log.

## 5. Revoking

Remove the tester's line from `authorized_keys`. That is immediate and affects
only them. Rotate the prover token as well if you believe the token itself
leaked — and tell every tester, because it breaks all of them.

## Hosted or local

A tester can use the hosted build with only this tunnel, provided the prover
answers a Private Network Access preflight with
`Access-Control-Allow-Private-Network: true`. Without that header Chrome does
not reject the request — it hangs with nothing in the console, which again reads
as a dead prover. Check before issuing:

```sh
curl -s -D - -o /dev/null -X OPTIONS \
  -H 'Origin: https://<hosted origin>' \
  -H 'Access-Control-Request-Method: GET' \
  -H 'Access-Control-Request-Private-Network: true' \
  'http://127.0.0.1:8805/attest?nonce=1' | grep -i private-network
```

If it is absent, the tester needs a locally served copy of the app instead, and
the hosted origin will not work no matter what else is correct.

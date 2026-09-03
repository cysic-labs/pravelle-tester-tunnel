#!/usr/bin/env bash
# SPDX-License-Identifier: MIT

set -Eeuo pipefail
export LC_ALL=C

test_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
project_dir="$(cd "$test_dir/.." && pwd)"
program="$project_dir/bin/pravelle-tester-tunnel"
fixture_path="$test_dir/fixtures"
tmp_dir="$(mktemp -d "${TMPDIR:-/tmp}/pravelle-tunnel-test.XXXXXX")"

cleanup() {
    rm -rf "$tmp_dir"
}
trap cleanup EXIT

pass_count=0

pass() {
    pass_count=$((pass_count + 1))
    printf 'ok %d - %s\n' "$pass_count" "$1"
}

fail() {
    printf 'not ok %d - %s\n' "$((pass_count + 1))" "$1" >&2
    exit 1
}

assert_arg() {
    expected="$1"
    grep -Fqx -- "$expected" "$tmp_dir/args" \
        || fail "missing SSH argument: $expected"
}

identity_file="$tmp_dir/tester_identity"
: > "$identity_file"
chmod 600 "$identity_file"

if PATH="$fixture_path:$PATH" \
    MOCK_SSH_MODE=clean \
    MOCK_SSH_ARGS="$tmp_dir/args" \
    "$program" restricted-test-host "$identity_file" \
    >"$tmp_dir/stdout" 2>"$tmp_dir/stderr"
then
    pass "valid restricted tunnel configuration is accepted"
else
    fail "valid restricted tunnel configuration should succeed"
fi

for expected in \
    "-N" \
    "-T" \
    "ExitOnForwardFailure=yes" \
    "StrictHostKeyChecking=yes" \
    "UpdateHostKeys=no" \
    "VerifyHostKeyDNS=no" \
    "IdentitiesOnly=yes" \
    "IdentityAgent=none" \
    "PasswordAuthentication=no" \
    "KbdInteractiveAuthentication=no" \
    "ControlMaster=no" \
    "ForwardAgent=no" \
    "ForwardX11=no" \
    "GatewayPorts=no" \
    "PermitLocalCommand=no" \
    "RemoteCommand=none" \
    "127.0.0.1:8798:127.0.0.1:8798" \
    "127.0.0.1:8799:127.0.0.1:8805" \
    "$identity_file" \
    "--" \
    "restricted-test-host"
do
    assert_arg "$expected"
done
pass "SSH invocation contains the required hardening and forwarding arguments"

# The remote layout is not this tool's to know, so the ports are overridable — and
# an override that is not a port must not reach the ssh command line.
if PATH="$fixture_path:$PATH" \
    MOCK_SSH_ARGS="$tmp_dir/args-override" \
    PRAVELLE_PROVER_PORT=9101 \
    PRAVELLE_MATCHER_PORT=9102 \
    "$program" restricted-test-host "$identity_file" \
    >"$tmp_dir/stdout" 2>"$tmp_dir/stderr"
then
    grep -Fq "127.0.0.1:8799:127.0.0.1:9101" "$tmp_dir/args-override" \
        || fail "prover port override should reach the forward"
    grep -Fq "127.0.0.1:8798:127.0.0.1:9102" "$tmp_dir/args-override" \
        || fail "matcher port override should reach the forward"
    pass "remote ports are overridable"
else
    fail "valid port overrides should be accepted"
fi

# An empty override is not in this list: `${VAR:-default}` treats empty as unset,
# so it falls back to the default rather than reaching validation. That is the
# intended reading of an empty variable, not a hole.
for bad in 0 70000 not-a-port 8805x -1; do
    if PATH="$fixture_path:$PATH" \
        MOCK_SSH_ARGS="$tmp_dir/args-bad" \
        PRAVELLE_PROVER_PORT="$bad" \
        "$program" restricted-test-host "$identity_file" \
        >"$tmp_dir/stdout" 2>"$tmp_dir/stderr"
    then
        fail "invalid prover port should be rejected: '$bad'"
    fi
done
pass "invalid remote ports are rejected"

if PATH="$fixture_path:$PATH" \
    MOCK_SSH_MODE=forward \
    MOCK_SSH_ARGS="$tmp_dir/args" \
    "$program" restricted-test-host "$identity_file" \
    >"$tmp_dir/stdout" 2>"$tmp_dir/stderr"
then
    fail "preconfigured forwarding should be rejected"
else
    grep -Fq "already defines a forward" "$tmp_dir/stderr" \
        || fail "forwarding rejection should explain the problem"
    pass "preconfigured SSH forwarding is rejected"
fi

if PATH="$fixture_path:$PATH" \
    MOCK_SSH_MODE=config-failure \
    MOCK_SSH_ARGS="$tmp_dir/args" \
    "$program" restricted-test-host "$identity_file" \
    >"$tmp_dir/stdout" 2>"$tmp_dir/stderr"
then
    fail "unresolvable SSH configuration should be rejected"
else
    grep -Fq "could not resolve SSH configuration" "$tmp_dir/stderr" \
        || fail "configuration failure should explain the problem"
    pass "SSH configuration failures are rejected"
fi

if PATH="$fixture_path:$PATH" \
    MOCK_SSH_MODE=clean \
    MOCK_SSH_ARGS="$tmp_dir/args" \
    "$program" restricted-test-host "$tmp_dir/missing_identity" \
    >"$tmp_dir/stdout" 2>"$tmp_dir/stderr"
then
    fail "missing identity should be rejected"
else
    grep -Fq "identity file does not exist" "$tmp_dir/stderr" \
        || fail "missing identity rejection should explain the problem"
    pass "missing identity files are rejected"
fi

chmod 644 "$identity_file"
if PATH="$fixture_path:$PATH" \
    MOCK_SSH_MODE=clean \
    MOCK_SSH_ARGS="$tmp_dir/args" \
    "$program" restricted-test-host "$identity_file" \
    >"$tmp_dir/stdout" 2>"$tmp_dir/stderr"
then
    fail "overly broad identity permissions should be rejected"
else
    grep -Fq "permissions must be 0400 or 0600" "$tmp_dir/stderr" \
        || fail "permission rejection should explain the problem"
    pass "overly broad identity-file permissions are rejected"
fi
chmod 600 "$identity_file"

if PATH="$fixture_path:$PATH" \
    MOCK_SSH_MODE=clean \
    MOCK_SSH_ARGS="$tmp_dir/args" \
    "$program" "-oProxyCommand=bad" "$identity_file" \
    >"$tmp_dir/stdout" 2>"$tmp_dir/stderr"
then
    fail "option-like SSH host should be rejected"
else
    grep -Fq "must not begin with '-'" "$tmp_dir/stderr" \
        || fail "option-like host rejection should explain the problem"
    pass "option-like SSH host values are rejected"
fi

printf '1..%d\n' "$pass_count"

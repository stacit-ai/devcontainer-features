#!/bin/bash
set -e
source dev-container-features-test-lib

check "codex is on PATH" codex --version
check "local ChatGPT auth initializes shared auth" bash -c '
    set -e
    root="$(mktemp -d)"
    trap '\''rm -rf "$root"'\'' EXIT
    mkdir -p "$root/local" "$root/shared"
    printf '\''{"tokens":{"access_token":"local"},"last_refresh":"2026-01-01T00:00:00Z"}\n'\'' > "$root/local/auth.json"
    CODEX_AUTH_LOCAL_FILE="$root/local/auth.json" \
    CODEX_AUTH_SHARED_DIR="$root/shared" \
    CODEX_AUTH_REMOTE_USER="$(id -un)" \
        sudo -E /usr/local/lib/codex-auth-sync once
    local_hash="$(sha256sum "$root/local/auth.json")"
    shared_hash="$(sudo sha256sum "$root/shared/auth.json")"
    test "${local_hash%% *}" = "${shared_hash%% *}"
    test "$(sudo stat -c '\''%U:%G:%a'\'' "$root/shared/auth.json")" = "root:root:600"
    test -z "$(sudo find "$root/shared" -name '\''auth.json.tmp.*'\'' -print -quit)"
'
check "equal auth files take the hash fast path" bash -c '
    set -e
    root="$(mktemp -d)"
    trap '\''rm -rf "$root"'\'' EXIT
    mkdir -p "$root/local" "$root/shared" "$root/bin"
    printf '\''not-json\n'\'' > "$root/local/auth.json"
    cp "$root/local/auth.json" "$root/shared/auth.json"
    cat > "$root/bin/sha256sum" <<'\''SCRIPT'\''
#!/bin/sh
printf x >> "$CODEX_HASH_MARKER"
exec /usr/bin/sha256sum "$@"
SCRIPT
    chmod +x "$root/bin/sha256sum"
    before="$(stat -c '\''%a:%Y'\'' "$root/local/auth.json" "$root/shared/auth.json")"
    CODEX_AUTH_LOCAL_FILE="$root/local/auth.json" \
    CODEX_AUTH_SHARED_DIR="$root/shared" \
    CODEX_AUTH_REMOTE_USER="$(id -un)" \
    CODEX_HASH_MARKER="$root/hash-called" \
    PATH="$root/bin:$PATH" \
        /usr/local/lib/codex-auth-sync once
    after="$(stat -c '\''%a:%Y'\'' "$root/local/auth.json" "$root/shared/auth.json")"
    test -s "$root/hash-called"
    test "$before" = "$after"
'
check "newer ChatGPT auth replaces older shared auth" bash -c '
    set -e
    root="$(mktemp -d)"
    trap '\''rm -rf "$root"'\'' EXIT
    mkdir -p "$root/local" "$root/shared"
    printf '\''{"tokens":{"access_token":"new"},"last_refresh":"2026-01-01T00:00:00.123Z"}\n'\'' > "$root/local/auth.json"
    printf '\''{"tokens":{"access_token":"old"},"last_refresh":"2025-12-31T23:59:59.999999999Z"}\n'\'' > "$root/shared/auth.json"
    CODEX_AUTH_LOCAL_FILE="$root/local/auth.json" \
    CODEX_AUTH_SHARED_DIR="$root/shared" \
    CODEX_AUTH_REMOTE_USER="$(id -un)" \
        sudo -E /usr/local/lib/codex-auth-sync once
    sudo jq -e '\''.tokens.access_token == "new"'\'' "$root/shared/auth.json" >/dev/null
'
check "background sync starts once and syncs immediately" bash -c '
    set -e
    root="$(mktemp -d)"
    trap '\''if test -f "$root/sync.pid"; then sudo sh -c "kill $(cat "$root/sync.pid")" 2>/dev/null || true; fi; sudo rm -rf "$root"'\'' EXIT
    mkdir -p "$root/local" "$root/shared"
    printf '\''{"tokens":{"access_token":"local"},"last_refresh":"2026-01-01T00:00:00Z"}\n'\'' > "$root/local/auth.json"
    CODEX_AUTH_LOCAL_FILE="$root/local/auth.json" \
    CODEX_AUTH_SHARED_DIR="$root/shared" \
    CODEX_AUTH_REMOTE_USER="$(id -un)" \
    CODEX_AUTH_PID_FILE="$root/sync.pid" \
    CODEX_AUTH_SYNC_INTERVAL=1 \
        sudo -E /usr/local/lib/codex-auth-sync start
    first_pid="$(cat "$root/sync.pid")"
    CODEX_AUTH_LOCAL_FILE="$root/local/auth.json" \
    CODEX_AUTH_SHARED_DIR="$root/shared" \
    CODEX_AUTH_REMOTE_USER="$(id -un)" \
    CODEX_AUTH_PID_FILE="$root/sync.pid" \
    CODEX_AUTH_SYNC_INTERVAL=1 \
        sudo -E /usr/local/lib/codex-auth-sync start
    test "$first_pid" = "$(cat "$root/sync.pid")"
    sudo sh -c "kill -0 $first_pid"
    for _ in 1 2 3 4 5; do
        test -f "$root/shared/auth.json" && break
        sleep 0.2
    done
    local_hash="$(sha256sum "$root/local/auth.json")"
    shared_hash="$(sudo sha256sum "$root/shared/auth.json")"
    test "${local_hash%% *}" = "${shared_hash%% *}"
'
check "API-key auth disables synchronization in both directions" bash -c '
    set -e
    root="$(mktemp -d)"
    trap '\''rm -rf "$root"'\'' EXIT
    mkdir -p "$root/local" "$root/shared"
    printf '\''{"OPENAI_API_KEY":"test-placeholder","tokens":null,"last_refresh":null}\n'\'' > "$root/local/auth.json"
    printf '\''{"tokens":{"access_token":"chatgpt-placeholder"},"last_refresh":"2026-01-01T00:00:00Z"}\n'\'' > "$root/shared/auth.json"
    before_local="$(sha256sum "$root/local/auth.json")"
    before_shared="$(sha256sum "$root/shared/auth.json")"
    CODEX_AUTH_LOCAL_FILE="$root/local/auth.json" \
    CODEX_AUTH_SHARED_DIR="$root/shared" \
    CODEX_AUTH_REMOTE_USER="$(id -un)" \
        sudo -E /usr/local/lib/codex-auth-sync once
    test "$before_local" = "$(sha256sum "$root/local/auth.json")"
    test "$before_shared" = "$(sha256sum "$root/shared/auth.json")"
'
check "unusable last_refresh values do not overwrite auth" bash -c '
    set -e
    root="$(mktemp -d)"
    trap '\''rm -rf "$root"'\'' EXIT
    mkdir -p "$root/local" "$root/shared"
    printf '\''{"tokens":{"access_token":"local"},"last_refresh":null}\n'\'' > "$root/local/auth.json"
    printf '\''{"tokens":{"access_token":"shared"},"last_refresh":"not-a-time"}\n'\'' > "$root/shared/auth.json"
    before_local="$(sha256sum "$root/local/auth.json")"
    before_shared="$(sha256sum "$root/shared/auth.json")"
    CODEX_AUTH_LOCAL_FILE="$root/local/auth.json" \
    CODEX_AUTH_SHARED_DIR="$root/shared" \
    CODEX_AUTH_REMOTE_USER="$(id -un)" \
        sudo -E /usr/local/lib/codex-auth-sync once
    test "$before_local" = "$(sha256sum "$root/local/auth.json")"
    test "$before_shared" = "$(sha256sum "$root/shared/auth.json")"
'
check "shared lock serializes concurrent sync" bash -c '
    set -e
    root="$(mktemp -d)"
    sync_pid=""
    trap '\''if test -n "$sync_pid"; then sudo sh -c "kill $sync_pid" 2>/dev/null || true; fi; sudo rm -rf "$root"'\'' EXIT
    mkdir -p "$root/local" "$root/shared"
    printf '\''{"tokens":{"access_token":"local"},"last_refresh":"2026-01-01T00:00:00Z"}\n'\'' > "$root/local/auth.json"
    touch "$root/shared/.sync.lock"
    exec 9>"$root/shared/.sync.lock"
    flock 9
    CODEX_AUTH_LOCAL_FILE="$root/local/auth.json" \
    CODEX_AUTH_SHARED_DIR="$root/shared" \
    CODEX_AUTH_REMOTE_USER="$(id -un)" \
        sudo -E /usr/local/lib/codex-auth-sync once &
    sync_pid="$!"
    sleep 0.2
    test ! -e "$root/shared/auth.json"
    flock -u 9
    wait "$sync_pid"
    sync_pid=""
    local_hash="$(sha256sum "$root/local/auth.json")"
    shared_hash="$(sudo sha256sum "$root/shared/auth.json")"
    test "${local_hash%% *}" = "${shared_hash%% *}"
'

reportResults

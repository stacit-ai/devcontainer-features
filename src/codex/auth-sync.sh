#!/bin/bash
set -euo pipefail

SHARED_DIR="${CODEX_AUTH_SHARED_DIR:-/var/lib/codex-auth}"
REMOTE_USER_FILE="${CODEX_AUTH_REMOTE_USER_FILE:-/etc/codex/remote-user}"
PID_FILE="${CODEX_AUTH_PID_FILE:-/run/codex-auth-sync.pid}"
SYNC_INTERVAL="${CODEX_AUTH_SYNC_INTERVAL:-60}"

log() {
    printf 'codex-auth-sync: %s\n' "$*" >&2
}

resolve_remote_user() {
    if [ -n "${CODEX_AUTH_REMOTE_USER:-}" ]; then
        printf '%s\n' "${CODEX_AUTH_REMOTE_USER}"
    else
        cat "${REMOTE_USER_FILE}"
    fi
}

resolve_local_file() {
    local remote_user="$1"
    local remote_home

    if [ -n "${CODEX_AUTH_LOCAL_FILE:-}" ]; then
        printf '%s\n' "${CODEX_AUTH_LOCAL_FILE}"
        return
    fi

    remote_home="$(getent passwd "${remote_user}" | cut -d: -f6)"
    if [ -z "${remote_home}" ]; then
        log "unable to resolve home directory for remote user"
        return 1
    fi
    printf '%s/.codex/auth.json\n' "${remote_home}"
}

is_valid_json() {
    jq -e 'type == "object"' "$1" >/dev/null 2>&1
}

is_api_key_auth() {
    jq -e '.OPENAI_API_KEY | type == "string" and length > 0' "$1" >/dev/null 2>&1
}

hash_file() {
    sha256sum "$1" | awk '{print $1}'
}

normalized_timestamp() {
    jq -er '
        .last_refresh
        | select(type == "string")
        | capture("^(?<base>[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2})(?:\\.(?<fraction>[0-9]{1,9}))?Z$")
        | (.base + "Z" | fromdateiso8601) as $epoch
        | ($epoch | strftime("%Y-%m-%dT%H:%M:%S"))
          + "."
          + ((((.fraction // "") + "000000000")[0:9]))
          + "Z"
    ' "$1" 2>/dev/null
}

copy_credential() {
    local source="$1"
    local destination="$2"
    local owner="$3"
    local directory

    directory="$(dirname "${destination}")"
    mkdir -p "${directory}"
    (
        local temporary

        temporary="$(mktemp "${destination}.tmp.XXXXXX")"
        trap 'rm -f "${temporary}"' EXIT
        cp -- "${source}" "${temporary}"
        if ! is_valid_json "${temporary}"; then
            log "refusing to install an invalid credential file"
            return 1
        fi
        chown "${owner}" "${temporary}"
        chmod 0600 "${temporary}"
        mv -f "${temporary}" "${destination}"
        trap - EXIT
    )
}

sync_once_locked() {
    local remote_user="$1"
    local local_file="$2"
    local shared_file="${SHARED_DIR}/auth.json"
    local local_timestamp remote_group shared_timestamp

    if [ -f "${local_file}" ] && [ -f "${shared_file}" ] &&
        [ "$(hash_file "${local_file}")" = "$(hash_file "${shared_file}")" ]; then
        return
    fi

    if [ -f "${local_file}" ] && [ -f "${shared_file}" ]; then
        if ! is_valid_json "${local_file}" || ! is_valid_json "${shared_file}"; then
            log "one or more credential files contain invalid JSON; skipping"
            return
        fi
        if is_api_key_auth "${local_file}" || is_api_key_auth "${shared_file}"; then
            log "API-key credentials are excluded from synchronization"
            return
        fi
        if ! local_timestamp="$(normalized_timestamp "${local_file}")" ||
            ! shared_timestamp="$(normalized_timestamp "${shared_file}")"; then
            log "last_refresh is missing or invalid; skipping"
            return
        fi

        if [[ "${local_timestamp}" > "${shared_timestamp}" ]]; then
            copy_credential "${local_file}" "${shared_file}" "root:root"
            log "updated shared ChatGPT credentials"
        elif [[ "${shared_timestamp}" > "${local_timestamp}" ]]; then
            remote_group="$(id -gn "${remote_user}")"
            mkdir -p "$(dirname "${local_file}")"
            chown "${remote_user}:${remote_group}" "$(dirname "${local_file}")"
            chmod 0700 "$(dirname "${local_file}")"
            copy_credential "${shared_file}" "${local_file}" "${remote_user}:${remote_group}"
            log "updated local ChatGPT credentials"
        fi
        return
    fi

    if [ -f "${local_file}" ]; then
        if ! is_valid_json "${local_file}"; then
            log "local credential file is invalid JSON; skipping"
            return
        fi
        if is_api_key_auth "${local_file}"; then
            log "API-key credentials are excluded from synchronization"
            return
        fi
        copy_credential "${local_file}" "${shared_file}" "root:root"
        log "initialized shared ChatGPT credentials"
        return
    fi

    if [ -f "${shared_file}" ]; then
        if ! is_valid_json "${shared_file}"; then
            log "shared credential file is invalid JSON; skipping"
            return
        fi
        if is_api_key_auth "${shared_file}"; then
            log "API-key credentials are excluded from synchronization"
            return
        fi
        remote_group="$(id -gn "${remote_user}")"
        mkdir -p "$(dirname "${local_file}")"
        chown "${remote_user}:${remote_group}" "$(dirname "${local_file}")"
        chmod 0700 "$(dirname "${local_file}")"
        copy_credential "${shared_file}" "${local_file}" "${remote_user}:${remote_group}"
        log "restored local ChatGPT credentials"
    fi
}

sync_once() {
    local remote_user local_file lock_file

    remote_user="$(resolve_remote_user)"
    local_file="$(resolve_local_file "${remote_user}")"
    mkdir -p "${SHARED_DIR}"
    lock_file="${SHARED_DIR}/.sync.lock"
    touch "${lock_file}"
    chmod 0600 "${lock_file}"
    (
        exec 9>"${lock_file}"
        flock 9
        sync_once_locked "${remote_user}" "${local_file}"
    )
}

remove_own_pid_file() {
    local recorded_pid

    recorded_pid="$(cat "${PID_FILE}" 2>/dev/null || true)"
    if [ "${recorded_pid}" = "$$" ]; then
        rm -f "${PID_FILE}"
    fi
}

run_loop() {
    case "${SYNC_INTERVAL}" in
        ''|*[!0-9]*|0)
            log "sync interval must be a positive integer"
            return 2
            ;;
    esac

    trap remove_own_pid_file EXIT
    trap 'exit 0' INT TERM
    while true; do
        if ! sync_once; then
            log "credential synchronization failed"
        fi
        sleep "${SYNC_INTERVAL}"
    done
}

start_loop() {
    local existing_pid new_pid pid_directory temporary_pid

    pid_directory="$(dirname "${PID_FILE}")"
    mkdir -p "${pid_directory}"
    (
        exec 8>"${PID_FILE}.lock"
        flock 8
        existing_pid="$(cat "${PID_FILE}" 2>/dev/null || true)"
        if [ -n "${existing_pid}" ] && kill -0 "${existing_pid}" 2>/dev/null; then
            return
        fi

        rm -f "${PID_FILE}"
        nohup "$0" loop 8>&- >/dev/null 2>&1 &
        new_pid="$!"
        temporary_pid="$(mktemp "${PID_FILE}.tmp.XXXXXX")"
        printf '%s\n' "${new_pid}" > "${temporary_pid}"
        chmod 0644 "${temporary_pid}"
        mv -f "${temporary_pid}" "${PID_FILE}"
    )
}

main() {
    case "${1:-}" in
        once) sync_once ;;
        loop) run_loop ;;
        start) start_loop ;;
        *)
            echo "ERROR: expected 'once', 'loop', or 'start'" >&2
            exit 2
            ;;
    esac
}

main "$@"

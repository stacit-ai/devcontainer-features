#!/bin/bash
set -e

source dev-container-features-test-lib

OLLAMA_MODEL="smollm2:135m"
OLLAMA_SERVER_PID_FILE="/tmp/ollama-server.pid"
OLLAMA_SERVER_LOG="/tmp/ollama-server.log"
OLLAMA_SMOLLM_OUTPUT="/tmp/ollama-smollm-output.txt"

cleanup_ollama_server() {
    if [ -f "${OLLAMA_SERVER_PID_FILE}" ]; then
        local pid
        pid="$(cat "${OLLAMA_SERVER_PID_FILE}")"
        if kill -0 "${pid}" > /dev/null 2>&1; then
            kill "${pid}" > /dev/null 2>&1 || true
            wait "${pid}" > /dev/null 2>&1 || true
        fi
    fi
}

start_ollama_server() {
    nohup ollama serve > "${OLLAMA_SERVER_LOG}" 2>&1 &
    echo "$!" > "${OLLAMA_SERVER_PID_FILE}"

    for _ in $(seq 1 60); do
        if ollama list > /dev/null 2>&1; then
            return 0
        fi

        if ! kill -0 "$(cat "${OLLAMA_SERVER_PID_FILE}")" > /dev/null 2>&1; then
            cat "${OLLAMA_SERVER_LOG}" >&2
            return 1
        fi

        sleep 1
    done

    cat "${OLLAMA_SERVER_LOG}" >&2
    return 1
}

run_smollm_smoke_test() {
    timeout 1200 ollama run "${OLLAMA_MODEL}" "Reply with only OK." > "${OLLAMA_SMOLLM_OUTPUT}"
}

trap cleanup_ollama_server EXIT

check "ollama is available" command -v ollama
check "ollama version works" ollama --version
check "OLLAMA_MODELS is configured" bash -c '[ "${OLLAMA_MODELS}" = "/opt/ollama/models" ]'
check "OLLAMA_MODELS directory is writable" bash -c 'touch /opt/ollama/models/.write-test'
check "default version metadata is recorded" grep -Fx "latest" /usr/local/share/ollama-feature/version
check "ollama server starts" start_ollama_server
check "smollm2 smoke test runs" run_smollm_smoke_test
check "smollm2 manifest is cached under OLLAMA_MODELS" test -f /opt/ollama/models/manifests/registry.ollama.ai/library/smollm2/135m
check "smollm2 blobs are cached under OLLAMA_MODELS" bash -c 'find /opt/ollama/models/blobs -type f -size +0c | grep -q .'

reportResults

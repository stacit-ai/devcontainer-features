#!/bin/bash
set -euo pipefail

OLLAMA_VERSION="${VERSION:-"latest"}"
INSTALL_DIR="/usr/local"
MODELS_DIR="/opt/ollama/models"
METADATA_DIR="/usr/local/share/ollama-feature"

require_command() {
    local command="$1"

    if ! command -v "${command}" > /dev/null 2>&1; then
        echo "ERROR: required command '${command}' not found" >&2
        exit 1
    fi
}

detect_arch() {
    case "$(uname -m)" in
        x86_64 | amd64)
            echo "amd64"
            ;;
        aarch64 | arm64)
            echo "arm64"
            ;;
        *)
            echo "ERROR: unsupported architecture for ollama: $(uname -m)" >&2
            exit 1
            ;;
    esac
}

version_query() {
    if [ "${OLLAMA_VERSION}" = "latest" ]; then
        echo ""
    else
        printf '?version=%s' "${OLLAMA_VERSION}"
    fi
}

download_and_extract() {
    local arch="$1"
    local filename="ollama-linux-${arch}"
    local query
    query="$(version_query)"

    if curl -fsSIL "https://ollama.com/download/${filename}.tar.zst${query}" > /dev/null 2>&1; then
        echo "Downloading ${filename}.tar.zst ..."
        curl -fsSL "https://ollama.com/download/${filename}.tar.zst${query}" | zstd -dc | tar -xf - -C "${INSTALL_DIR}"
    else
        echo "Downloading ${filename}.tgz ..."
        curl -fsSL "https://ollama.com/download/${filename}.tgz${query}" | tar -xzf - -C "${INSTALL_DIR}"
    fi
}

prepare_models_dir() {
    mkdir -p "${MODELS_DIR}"
    chmod -R o+rwX "${MODELS_DIR}"
}

write_metadata() {
    mkdir -p "${METADATA_DIR}"
    printf '%s\n' "${OLLAMA_VERSION}" > "${METADATA_DIR}/version"
    printf '%s\n' "${MODELS_DIR}" > "${METADATA_DIR}/models_dir"
}

main() {
    local arch

    require_command curl
    require_command tar
    require_command zstd

    arch="$(detect_arch)"
    rm -rf "${INSTALL_DIR}/lib/ollama"
    download_and_extract "${arch}"
    prepare_models_dir
    write_metadata

    echo "==> ollama feature installation complete."
}

main "$@"

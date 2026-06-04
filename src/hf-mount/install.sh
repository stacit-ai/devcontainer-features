#!/bin/bash
set -euo pipefail

HF_MOUNT_VERSION="${VERSION:-"latest"}"
INSTALL_DIR="/usr/local/bin"
METADATA_DIR="/usr/local/share/hf-mount-feature"
RELEASE_BASE_URL="https://github.com/huggingface/hf-mount/releases"
TEMP_DIR=""

require_command() {
    local command="$1"

    if ! command -v "${command}" > /dev/null 2>&1; then
        echo "ERROR: required command '${command}' not found" >&2
        exit 1
    fi
}

detect_asset_arch() {
    case "$(uname -m)" in
        x86_64 | amd64)
            echo "x86_64"
            ;;
        aarch64 | arm64)
            echo "aarch64"
            ;;
        *)
            echo "ERROR: unsupported architecture for hf-mount: $(uname -m)" >&2
            exit 1
            ;;
    esac
}

normalize_version_tag() {
    local version="$1"

    if [ "${version}" = "latest" ]; then
        echo "latest"
    elif [[ "${version}" == v* ]]; then
        echo "${version}"
    else
        echo "v${version}"
    fi
}

get_download_url() {
    local tag="$1"
    local asset="$2"

    if [ "${tag}" = "latest" ]; then
        echo "${RELEASE_BASE_URL}/latest/download/${asset}"
    else
        echo "${RELEASE_BASE_URL}/download/${tag}/${asset}"
    fi
}

install_binary() {
    local tag="$1"
    local asset="$2"
    local target_name="$3"
    local temp_dir="$4"
    local download_path="${temp_dir}/${asset}"

    echo "Downloading ${asset} from hf-mount ${tag} ..."
    curl -fsSL "$(get_download_url "${tag}" "${asset}")" -o "${download_path}"
    install -m 0755 "${download_path}" "${INSTALL_DIR}/${target_name}"
}

write_metadata() {
    local tag="$1"

    mkdir -p "${METADATA_DIR}"
    printf '%s\n' "${tag}" > "${METADATA_DIR}/version"
}

cleanup() {
    if [ -n "${TEMP_DIR}" ]; then
        rm -rf "${TEMP_DIR}"
    fi
}

main() {
    local arch
    local tag

    require_command curl

    arch="$(detect_asset_arch)"
    tag="$(normalize_version_tag "${HF_MOUNT_VERSION}")"
    TEMP_DIR="$(mktemp -d)"
    trap cleanup EXIT

    install_binary "${tag}" "hf-mount-${arch}-linux" "hf-mount" "${TEMP_DIR}"
    install_binary "${tag}" "hf-mount-nfs-${arch}-linux" "hf-mount-nfs" "${TEMP_DIR}"
    write_metadata "${tag}"

    echo "==> hf-mount feature installation complete."
}

main "$@"

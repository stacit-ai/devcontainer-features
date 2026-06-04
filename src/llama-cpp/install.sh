#!/bin/bash
set -euo pipefail

LLAMA_CPP_VERSION="${VERSION:-"latest"}"
LLAMA_CPP_BACKEND="${BACKEND:-"cpu"}"
INSTALL_DIR="/usr/local/bin"
LIB_DIR="/usr/local/lib/llama-cpp"
METADATA_DIR="/usr/local/share/llama-cpp-feature"
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
            echo "x64"
            ;;
        aarch64 | arm64)
            echo "arm64"
            ;;
        *)
            echo "ERROR: unsupported architecture for llama-cpp: $(uname -m)" >&2
            exit 1
            ;;
    esac
}

release_api_url() {
    local version="$1"

    if [ "${version}" = "latest" ]; then
        echo "https://api.github.com/repos/ggml-org/llama.cpp/releases/latest"
    else
        echo "https://api.github.com/repos/ggml-org/llama.cpp/releases/tags/${version}"
    fi
}

resolve_release_json() {
    local version="$1"

    curl -fsSL "$(release_api_url "${version}")"
}

resolve_release_tag() {
    local release_json="$1"

    printf '%s\n' "${release_json}" | sed -n 's/.*"tag_name": *"\([^"]*\)".*/\1/p' | head -n 1
}

asset_pattern() {
    local tag="$1"
    local backend="$2"
    local arch="$3"

    case "${backend}" in
        cpu)
            printf 'llama-%s-bin-ubuntu-%s\\.tar\\.gz$' "${tag}" "${arch}"
            ;;
        cuda)
            printf 'llama-%s-bin-ubuntu-cuda-.*-%s\\.tar\\.gz$' "${tag}" "${arch}"
            ;;
        vulkan)
            printf 'llama-%s-bin-ubuntu-vulkan-%s\\.tar\\.gz$' "${tag}" "${arch}"
            ;;
        rocm)
            printf 'llama-%s-bin-ubuntu-rocm-.*-%s\\.tar\\.gz$' "${tag}" "${arch}"
            ;;
        openvino)
            printf 'llama-%s-bin-ubuntu-openvino-.*-%s\\.tar\\.gz$' "${tag}" "${arch}"
            ;;
        *)
            echo "ERROR: unsupported llama-cpp backend: ${backend}" >&2
            exit 1
            ;;
    esac
}

select_asset_url() {
    local release_json="$1"
    local tag="$2"
    local backend="$3"
    local arch="$4"
    local pattern

    pattern="$(asset_pattern "${tag}" "${backend}" "${arch}")"
    printf '%s\n' "${release_json}" \
        | sed -n 's/.*"browser_download_url": *"\([^"]*\)".*/\1/p' \
        | grep -E "${pattern}" \
        | head -n 1 || true
}

copy_release_tree() {
    local extracted_root

    extracted_root="$(find "${TEMP_DIR}" -mindepth 1 -maxdepth 1 -type d | head -n 1)"
    if [ -z "${extracted_root}" ]; then
        echo "ERROR: unable to find extracted llama-cpp release directory" >&2
        exit 1
    fi

    rm -rf "${LIB_DIR}"
    mkdir -p "${LIB_DIR}"
    cp -a "${extracted_root}/." "${LIB_DIR}/"
}

install_binary_wrapper() {
    local binary="$1"
    local source_path

    source_path="$(find "${LIB_DIR}" -type f -name "${binary}" | head -n 1)"
    if [ -z "${source_path}" ]; then
        echo "ERROR: ${binary} not found in llama-cpp release asset" >&2
        exit 1
    fi

    cat > "${INSTALL_DIR}/${binary}" <<EOF
#!/bin/sh
export LD_LIBRARY_PATH="${LIB_DIR}:\${LD_LIBRARY_PATH:-}"
exec "${source_path}" "\$@"
EOF
    chmod 0755 "${INSTALL_DIR}/${binary}"
}

write_metadata() {
    local tag="$1"
    local backend="$2"
    local asset_url="$3"

    mkdir -p "${METADATA_DIR}"
    printf '%s\n' "${tag}" > "${METADATA_DIR}/version"
    printf '%s\n' "${backend}" > "${METADATA_DIR}/backend"
    basename "${asset_url}" > "${METADATA_DIR}/asset"
}

cleanup() {
    if [ -n "${TEMP_DIR}" ]; then
        rm -rf "${TEMP_DIR}"
    fi
}

main() {
    local arch
    local release_json
    local tag
    local asset_url

    require_command curl
    require_command tar
    require_command find
    require_command grep
    require_command sed

    arch="$(detect_asset_arch)"
    release_json="$(resolve_release_json "${LLAMA_CPP_VERSION}")"
    tag="$(resolve_release_tag "${release_json}")"

    if [ -z "${tag}" ]; then
        echo "ERROR: unable to resolve llama-cpp release tag for ${LLAMA_CPP_VERSION}" >&2
        exit 1
    fi

    asset_url="$(select_asset_url "${release_json}" "${tag}" "${LLAMA_CPP_BACKEND}" "${arch}")"
    if [ -z "${asset_url}" ]; then
        echo "ERROR: no llama-cpp ${LLAMA_CPP_BACKEND} asset found for ${tag} on ${arch}" >&2
        exit 1
    fi

    TEMP_DIR="$(mktemp -d)"
    trap cleanup EXIT

    echo "Downloading $(basename "${asset_url}") ..."
    curl -fsSL "${asset_url}" | tar -xzf - -C "${TEMP_DIR}"
    copy_release_tree
    install_binary_wrapper llama-server
    install_binary_wrapper llama-cli
    write_metadata "${tag}" "${LLAMA_CPP_BACKEND}" "${asset_url}"

    echo "==> llama-cpp feature installation complete."
}

main "$@"

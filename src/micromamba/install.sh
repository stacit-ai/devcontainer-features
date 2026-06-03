#!/bin/bash
set -euo pipefail

MICROMAMBA_VERSION="${VERSION:-"latest"}"
INIT_SHELL="${INITSHELL:-"auto"}"

MAMBA_ROOT_PREFIX="${_REMOTE_USER_HOME}/micromamba"
DOWNLOAD_PATH="/tmp/micromamba"
MICROMAMBA_BIN_DIR="/usr/local/lib/micromamba"
MICROMAMBA_EXE="${MICROMAMBA_BIN_DIR}/micromamba"

remote_user_do() {
    if [ -n "${_REMOTE_USER:-}" ] && [ "${_REMOTE_USER}" != "root" ]; then
        sudo -i -u "${_REMOTE_USER}" -- "$@"
    else
        "$@"
    fi
}

require_command() {
    local command="$1"

    if ! command -v "${command}" > /dev/null 2>&1; then
        echo "ERROR: required command '${command}' not found" >&2
        exit 1
    fi
}

verify_supported_linux() {
    if [ "$(uname)" != "Linux" ]; then
        echo "ERROR: micromamba feature only supports Linux containers." >&2
        exit 1
    fi

    if command -v ldd > /dev/null 2>&1 && ldd --version 2>&1 | grep -qi "musl"; then
        echo "ERROR: micromamba feature requires a glibc-based Linux image; Alpine/musl is not supported." >&2
        exit 1
    fi
}

get_platform() {
    case "$(uname -m)" in
        x86_64 | amd64)
            printf '%s\n' "linux-64"
            ;;
        aarch64 | arm64)
            printf '%s\n' "linux-aarch64"
            ;;
        ppc64le)
            printf '%s\n' "linux-ppc64le"
            ;;
        *)
            echo "ERROR: unsupported architecture for micromamba: $(uname -m)" >&2
            exit 1
            ;;
    esac
}

get_download_url() {
    if [ "${MICROMAMBA_VERSION}" = "latest" ]; then
        printf 'https://github.com/mamba-org/micromamba-releases/releases/latest/download/micromamba-%s\n' "$(get_platform)"
    else
        printf 'https://github.com/mamba-org/micromamba-releases/releases/download/%s/micromamba-%s\n' \
            "${MICROMAMBA_VERSION}" "$(get_platform)"
    fi
}

download_micromamba() {
    local download_url

    download_url="$(get_download_url)"
    echo "Downloading micromamba from ${download_url} ..."
    curl -fsSL "${download_url}" -o "${DOWNLOAD_PATH}"
}

install_micromamba() {
    echo "Installing micromamba to ${MICROMAMBA_EXE} ..."
    install -d -m 0755 "${MICROMAMBA_BIN_DIR}"
    install -m 0755 "${DOWNLOAD_PATH}" "${MICROMAMBA_EXE}"
}

create_command_wrapper() {
    cat > /usr/local/bin/micromamba <<'EOF'
#!/bin/sh
if [ -z "${MAMBA_ROOT_PREFIX:-}" ]; then
    export MAMBA_ROOT_PREFIX="${HOME}/micromamba"
fi
exec /usr/local/lib/micromamba/micromamba "$@"
EOF
    chmod 0755 /usr/local/bin/micromamba
}

prepare_root_prefix() {
    mkdir -p "${MAMBA_ROOT_PREFIX}"
    chown -R "${_REMOTE_USER}:${_REMOTE_USER}" "${MAMBA_ROOT_PREFIX}"
}

detect_remote_shell() {
    local login_shell=""

    if [ -n "${_REMOTE_USER:-}" ] && command -v getent > /dev/null 2>&1; then
        login_shell="$(getent passwd "${_REMOTE_USER}" | cut -d: -f7 || true)"
    fi

    if [ -z "${login_shell}" ]; then
        printf '%s\n' "bash"
        return
    fi

    basename "${login_shell}"
}

resolve_shell_to_init() {
    if [ "${INIT_SHELL}" = "auto" ]; then
        detect_remote_shell
    else
        printf '%s\n' "${INIT_SHELL}"
    fi
}

validate_shell() {
    case "$1" in
        bash | zsh | fish | tcsh | xonsh | powershell | nu)
            ;;
        *)
            echo "ERROR: unsupported shell for micromamba shell init: $1" >&2
            exit 1
            ;;
    esac
}

initialize_shell() {
    local shell_name

    if [ "${INIT_SHELL}" = "none" ]; then
        echo "Skipping micromamba shell initialization."
        return
    fi

    shell_name="$(resolve_shell_to_init)"
    validate_shell "${shell_name}"

    echo "Initializing micromamba for ${shell_name} ..."
    remote_user_do /usr/local/bin/micromamba shell init -s "${shell_name}" -r "${MAMBA_ROOT_PREFIX}"
}

main() {
    require_command curl
    require_command sudo
    verify_supported_linux

    download_micromamba
    install_micromamba
    create_command_wrapper
    prepare_root_prefix
    initialize_shell

    echo "==> micromamba feature installation complete."
}

main "$@"

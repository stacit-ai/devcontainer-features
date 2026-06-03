#!/bin/bash
set -euo pipefail

MINIFORGE_VERSION="${VERSION:-"latest"}"
INIT_SHELL="${INITSHELL:-"auto"}"

MINIFORGE_PREFIX="${_REMOTE_USER_HOME}/.miniforge3"
INSTALLER_PATH="/tmp/miniforge-installer.sh"

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

get_architecture() {
    uname -m
}

get_download_url() {
    local architecture

    architecture="$(get_architecture)"
    if [ "${MINIFORGE_VERSION}" = "latest" ]; then
        printf 'https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-%s.sh\n' "${architecture}"
    else
        printf 'https://github.com/conda-forge/miniforge/releases/download/%s/Miniforge3-%s-Linux-%s.sh\n' \
            "${MINIFORGE_VERSION}" "${MINIFORGE_VERSION}" "${architecture}"
    fi
}

download_installer() {
    local download_url

    download_url="$(get_download_url)"
    echo "Downloading Miniforge installer from ${download_url} ..."
    curl -fsSL "${download_url}" -o "${INSTALLER_PATH}"
    chmod +x "${INSTALLER_PATH}"
}

install_miniforge() {
    local install_args=("-b" "-p" "${MINIFORGE_PREFIX}")

    if [ -d "${MINIFORGE_PREFIX}" ]; then
        install_args+=("-u")
    fi

    echo "Installing Miniforge to ${MINIFORGE_PREFIX} ..."
    remote_user_do bash "${INSTALLER_PATH}" "${install_args[@]}"
}

create_command_links() {
    ln -sf "${MINIFORGE_PREFIX}/bin/conda" /usr/local/bin/conda
    ln -sf "${MINIFORGE_PREFIX}/bin/mamba" /usr/local/bin/mamba
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
        bash | zsh | fish | tcsh | xonsh | powershell)
            ;;
        *)
            echo "ERROR: unsupported shell for conda init: $1" >&2
            exit 1
            ;;
    esac
}

initialize_shell() {
    local shell_name

    if [ "${INIT_SHELL}" = "none" ]; then
        echo "Skipping conda shell initialization."
        return
    fi

    shell_name="$(resolve_shell_to_init)"
    validate_shell "${shell_name}"

    echo "Initializing conda for ${shell_name} ..."
    remote_user_do "${MINIFORGE_PREFIX}/bin/conda" init "${shell_name}"
}

main() {
    require_command curl
    require_command sudo
    require_command bash

    download_installer
    install_miniforge
    create_command_links
    initialize_shell

    echo "==> Miniforge feature installation complete."
}

main "$@"

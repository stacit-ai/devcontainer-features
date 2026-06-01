#!/bin/bash
set -euo pipefail

# Feature options injected by devcontainer CLI.
UV_VERSION="${VERSION:-"latest"}"

UV_OPT_DIR="/opt/uv"
TOOLS_TO_INSTALL="${TOOLSTOINSTALL:-}"

uv_command_path=""

remote_user_do() {
    if [ -n "${_REMOTE_USER:-}" ] && [ "${_REMOTE_USER}" != "root" ]; then
        sudo -i -u "${_REMOTE_USER}" -- "$@"
    else
        "$@"
    fi
}

set_remote_ownership() {
    chown -R "${_REMOTE_USER}:${_REMOTE_USER}" "$@"
}

install_apt_deps() {
    apt-get update -y
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends "$@"
}

install_apk_deps() {
    apk add --no-cache "$@"
}

install_dnf_deps() {
    dnf install -y "$@"
}

install_yum_deps() {
    yum install -y "$@"
}

install_pacman_deps() {
    pacman -Sy --noconfirm "$@"
}

detect_package_manager() {
    if command -v apt-get > /dev/null 2>&1; then
        echo apt
    elif command -v apk > /dev/null 2>&1; then
        echo apk
    elif command -v dnf > /dev/null 2>&1; then
        echo dnf
    elif command -v yum > /dev/null 2>&1; then
        echo yum
    elif command -v pacman > /dev/null 2>&1; then
        echo pacman
    else
        echo "ERROR: unsupported package manager for uv feature" >&2
        exit 1
    fi
}

install_deps() {
    case "$(detect_package_manager)" in
        apt) install_apt_deps "$@" ;;
        apk) install_apk_deps "$@" ;;
        dnf) install_dnf_deps "$@" ;;
        yum) install_yum_deps "$@" ;;
        pacman) install_pacman_deps "$@" ;;
        *)
            echo "ERROR: unsupported package manager for uv feature" >&2
            exit 1
            ;;
    esac
}

trim_whitespace() {
    local value="$1"

    value="${value#"${value%%[![:space:]]*}"}"
    value="${value%"${value##*[![:space:]]}"}"
    printf '%s' "$value"
}

install_prerequisites() {
    echo "==> Installing prerequisites..."
    install_deps curl ca-certificates sudo
}

install_uv() {
    local version="$UV_VERSION"
    local download_url=""
    echo "Installing UV version: $version"
    if [ "$version" = "latest" ]; then
        download_url="https://astral.sh/uv/install.sh"
    else
        download_url="https://astral.sh/uv/${version}/install.sh"
    fi

    echo "Downloading and running UV installer from $download_url ..."
    curl -LsSf "$download_url" | remote_user_do sh
    echo "UV installation completed."
}

prepare_uv_dirs() {
    echo "Preparing UV cache and config directories at ${UV_OPT_DIR} ..."
    mkdir -p "${UV_OPT_DIR}/cache" "${UV_OPT_DIR}/python" "${UV_OPT_DIR}/venv"
    set_remote_ownership "${UV_OPT_DIR}"
    chmod -R o+rwX "${UV_OPT_DIR}"
}

install_uv_tools() {
    local raw_tools=()
    local tool_name
    local tools=()

    uv_command_path="${_REMOTE_USER_HOME}/.local/bin/uv"

    if [ -z "${TOOLS_TO_INSTALL}" ]; then
        echo "No uv tools requested. Skipping tool installation."
        return
    fi

    IFS=',' read -r -a raw_tools <<< "${TOOLS_TO_INSTALL}"
    for tool_name in "${raw_tools[@]}"; do
        tool_name="$(trim_whitespace "${tool_name}")"
        if [ -n "${tool_name}" ]; then
            tools+=("${tool_name}")
        fi
    done

    if [ "${#tools[@]}" -eq 0 ]; then
        echo "No uv tools to install after filtering."
        return
    fi

    for tool_name in "${tools[@]}"; do
        echo "Installing uv tool: ${tool_name}"
        remote_user_do "${uv_command_path}" tool install "${tool_name}"
    done
}

main() {
    install_prerequisites
    prepare_uv_dirs
    install_uv
    install_uv_tools
    echo "==> uv feature installation complete."
}

main "$@"

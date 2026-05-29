#!/bin/bash
set -euo pipefail

# Feature options injected by devcontainer CLI.
UV_VERSION="${VERSION:-"latest"}"
TOOLS_TO_INSTALL="${TOOLSTOINSTALL-"ruff,pytest,ty,black,pyright,pre-commit,rust-just"}"

UV_OPT_DIR="/opt/uv"

require_command() {
    local cmd="$1"
    if ! command -v "${cmd}" > /dev/null 2>&1; then
        echo "ERROR: required command '${cmd}' not found" >&2
        exit 1
    fi
}

remote_user_do() {
    if [ "$(id -u)" -eq 0 ] && [ "${_REMOTE_USER}" != "root" ]; then
        local command
        printf -v command "%q " "$@"
        su "${_REMOTE_USER}" -c "${command}"
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

install_prerequisites() {
    echo "==> Installing prerequisites..."
    install_deps curl ca-certificates
    require_command curl
}

create_uv_cache_dirs() {
    echo "==> Creating /opt/uv/ directory skeleton..."
    mkdir -p \
        "${UV_OPT_DIR}/python" \
        "${UV_OPT_DIR}/cache" \
        "${UV_OPT_DIR}/venv"
    set_remote_ownership "${UV_OPT_DIR}"
}

install_uv() {
    echo "==> Installing uv (version: ${UV_VERSION})..."
    if [ "${UV_VERSION}" = "latest" ]; then
        curl -LsSf https://astral.sh/uv/install.sh \
            | env UV_UNMANAGED_INSTALL="/usr/local/bin" sh
    else
        curl -LsSf https://astral.sh/uv/install.sh \
            | env UV_UNMANAGED_INSTALL="/usr/local/bin" UV_VERSION="${UV_VERSION}" sh
    fi
    require_command uv
}

print_uv_version() {
    echo "    uv $(uv --version)"
}

parse_tools_to_install() {
    local -a raw_tools
    local raw
    local tool

    IFS=',' read -ra raw_tools <<< "${TOOLS_TO_INSTALL}"
    for raw in "${raw_tools[@]}"; do
        tool="${raw// /}"
        [ -z "${tool}" ] && continue
        echo "${tool}"
    done
}

install_uv_tool() {
    local tool="$1"

    echo "    -> uv tool install ${tool}"
    remote_user_do env \
        HOME="${_REMOTE_USER_HOME}" \
        UV_CACHE_DIR="${UV_OPT_DIR}/cache" \
        /usr/local/bin/uv tool install "${tool}"
}

install_uv_tools() {
    if [ -z "${TOOLS_TO_INSTALL}" ]; then
        echo "==> toolsToInstall is empty — skipping tool installation."
        return
    fi

    echo "==> Installing tools: ${TOOLS_TO_INSTALL}"
    while IFS= read -r tool; do
        install_uv_tool "${tool}"
    done < <(parse_tools_to_install)
}

main() {
    install_prerequisites
    create_uv_cache_dirs
    install_uv
    print_uv_version
    install_uv_tools
    set_remote_ownership "${UV_OPT_DIR}"
    echo "==> uv feature installation complete."
}

main "$@"

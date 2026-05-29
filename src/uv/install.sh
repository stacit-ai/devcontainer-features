#!/bin/bash
set -euo pipefail

# ---------------------------------------------------------------------------
# Remote user
# ---------------------------------------------------------------------------
REMOTE_USER="${_REMOTE_USER:-"$(id -un)"}"
REMOTE_USER_HOME="${_REMOTE_USER_HOME:-"$(eval echo "~${REMOTE_USER}")"}"

# ---------------------------------------------------------------------------
# Feature options (injected by devcontainer CLI as env vars)
# ---------------------------------------------------------------------------
UV_VERSION="${VERSION:-"latest"}"
TOOLS_TO_INSTALL="${TOOLSTOINSTALL:-"ruff,pytest,ty,black,pyright,pre-commit,rust-just"}"

# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------
UV_OPT_DIR="/opt/uv"           # volume mount point — cache only
UV_TOOL_BASE="/usr/local/share/uv"  # image layer — tool storage

# ---------------------------------------------------------------------------
# Helper: run a command as the remote user
# ---------------------------------------------------------------------------
remote_user_do() {
    if [ "$(id -u)" -eq 0 ] && [ "${REMOTE_USER}" != "root" ]; then
        su --login "${REMOTE_USER}" -- "$@"
    else
        "$@"
    fi
}

# ---------------------------------------------------------------------------
# Helper: assert a command exists on PATH
# ---------------------------------------------------------------------------
require_command() {
    local cmd="$1"
    if ! command -v "${cmd}" > /dev/null 2>&1; then
        echo "ERROR: required command '${cmd}' not found" >&2
        exit 1
    fi
}

# ---------------------------------------------------------------------------
# OS / distro detection
# ---------------------------------------------------------------------------
# shellcheck source=/dev/null
. /etc/os-release
OS_ID="${ID:-unknown}"
OS_ID_LIKE="${ID_LIKE:-}"

is_debian_family() {
    [[ "${OS_ID}" == "debian" || "${OS_ID}" == "ubuntu" \
        || "${OS_ID_LIKE}" =~ debian ]]
}

is_fedora_family() {
    [[ "${OS_ID}" == "fedora" || "${OS_ID}" == "rhel" \
        || "${OS_ID}" == "almalinux" \
        || "${OS_ID_LIKE}" =~ rhel || "${OS_ID_LIKE}" =~ fedora ]]
}

is_arch_linux() {
    [[ "${OS_ID}" == "arch" || "${OS_ID_LIKE}" =~ arch ]]
}

is_alpine() {
    [[ "${OS_ID}" == "alpine" ]]
}

# ---------------------------------------------------------------------------
# Helper: install OS packages (distro-aware)
# ---------------------------------------------------------------------------
install_packages() {
    if is_debian_family; then
        DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends "$@"
    elif is_fedora_family; then
        dnf install -y "$@"
    elif is_arch_linux; then
        pacman -Sy --noconfirm "$@"
    elif is_alpine; then
        apk add --no-cache "$@"
    else
        echo "WARNING: unknown distro — skipping package install for: $*" >&2
    fi
}

# ---------------------------------------------------------------------------
# 1. Install prerequisites (curl + TLS)
# ---------------------------------------------------------------------------
echo "==> Installing prerequisites..."
if ! command -v curl > /dev/null 2>&1; then
    if is_debian_family; then
        apt-get update -y
        install_packages curl ca-certificates
    elif is_fedora_family; then
        install_packages curl ca-certificates
    elif is_arch_linux; then
        pacman -Sy --noconfirm
        install_packages curl ca-certificates
    elif is_alpine; then
        install_packages curl ca-certificates
    fi
fi
require_command curl

# ---------------------------------------------------------------------------
# 2. Create directory skeleton under /opt/uv/ (volume mount point)
#    These sub-directories are created in the image layer here.
#    When the volume is mounted at container start, it creates its own
#    directories on first use — but having them pre-created avoids
#    permission errors when uv first writes.
# ---------------------------------------------------------------------------
echo "==> Creating /opt/uv/ directory skeleton..."
mkdir -p \
    "${UV_OPT_DIR}/python" \
    "${UV_OPT_DIR}/cache" \
    "${UV_OPT_DIR}/venv"
chown -R "${REMOTE_USER}:${REMOTE_USER}" "${UV_OPT_DIR}"

# ---------------------------------------------------------------------------
# 3. Create tool storage directories (image layer, outside volume)
# ---------------------------------------------------------------------------
echo "==> Creating tool storage directories..."
mkdir -p \
    "${UV_TOOL_BASE}/tools" \
    "${UV_TOOL_BASE}/bin"
chown -R "${REMOTE_USER}:${REMOTE_USER}" "${UV_TOOL_BASE}"

# ---------------------------------------------------------------------------
# 4. Write environment variables to /etc/profile.d/uv.sh
#    Sourced by login shells on all major distros.
# ---------------------------------------------------------------------------
echo "==> Writing /etc/profile.d/uv.sh..."
cat > /etc/profile.d/uv.sh << 'EOF'
# uv devcontainer feature — environment configuration
export UV_PYTHON_INSTALL_DIR="/opt/uv/python"
export UV_CACHE_DIR="/opt/uv/cache"
export UV_PROJECT_ENVIRONMENT="/opt/uv/venv"
export UV_TOOL_DIR="/usr/local/share/uv/tools"
export UV_TOOL_BIN_DIR="/usr/local/share/uv/bin"
export PATH="/usr/local/share/uv/bin:${PATH}"
EOF
chmod 644 /etc/profile.d/uv.sh

# ---------------------------------------------------------------------------
# 5. Install uv binary
#    UV_UNMANAGED_INSTALL places the binary in the given directory and
#    disables uv's self-update mechanism — appropriate for devcontainers.
# ---------------------------------------------------------------------------
echo "==> Installing uv (version: ${UV_VERSION})..."
if [ "${UV_VERSION}" = "latest" ]; then
    curl -LsSf https://astral.sh/uv/install.sh \
        | env UV_UNMANAGED_INSTALL="/usr/local/bin" sh
else
    curl -LsSf https://astral.sh/uv/install.sh \
        | env UV_UNMANAGED_INSTALL="/usr/local/bin" UV_VERSION="${UV_VERSION}" sh
fi

require_command uv
echo "    uv $(uv --version)"

# ---------------------------------------------------------------------------
# 6. Install tools via `uv tool install` (run as remote user)
#    UV env vars are passed explicitly because `su --login` resets the
#    environment and /etc/profile.d/ may not be sourced before uv runs.
# ---------------------------------------------------------------------------
if [ -z "${TOOLS_TO_INSTALL}" ]; then
    echo "==> toolsToInstall is empty — skipping tool installation."
else
    echo "==> Installing tools: ${TOOLS_TO_INSTALL}"

    # Split on comma, strip whitespace, skip empty entries
    IFS=',' read -ra RAW_TOOLS <<< "${TOOLS_TO_INSTALL}"
    for raw in "${RAW_TOOLS[@]}"; do
        tool="${raw// /}"   # strip spaces
        [ -z "${tool}" ] && continue

        echo "    -> uv tool install ${tool}"
        remote_user_do env \
            HOME="${REMOTE_USER_HOME}" \
            PATH="/usr/local/bin:/usr/local/share/uv/bin:${PATH}" \
            UV_TOOL_DIR="${UV_TOOL_BASE}/tools" \
            UV_TOOL_BIN_DIR="${UV_TOOL_BASE}/bin" \
            UV_CACHE_DIR="${UV_OPT_DIR}/cache" \
            uv tool install "${tool}"
    done
fi

# ---------------------------------------------------------------------------
# 7. Ensure /opt/uv/ ownership is correct after any writes
# ---------------------------------------------------------------------------
chown -R "${REMOTE_USER}:${REMOTE_USER}" "${UV_OPT_DIR}"
chown -R "${REMOTE_USER}:${REMOTE_USER}" "${UV_TOOL_BASE}"

echo "==> uv feature installation complete."

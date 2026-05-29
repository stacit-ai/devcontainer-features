# Knowledge Base — install.sh Code Snippets

Self-contained reusable patterns for `src/<name>/install.sh`.
Copy and adapt as needed; no external dependency on other features.

---

## Script Header

Every `install.sh` must start with these two lines:

```bash
#!/bin/bash
set -euo pipefail
```

---

## Remote User Detection

devcontainer sets `_REMOTE_USER` and `_REMOTE_USER_HOME` at image-build time.
Read them early; fall back gracefully if they are absent (e.g. plain Docker).

```bash
REMOTE_USER="${_REMOTE_USER:-"$(id -un)"}"
REMOTE_USER_HOME="${_REMOTE_USER_HOME:-"$(eval echo "~${REMOTE_USER}")"}"
```

---

## Helper Functions

### `remote_user_do` — run a command as the remote user

```bash
remote_user_do() {
    if [ "$(id -u)" -eq 0 ] && [ "${REMOTE_USER}" != "root" ]; then
        su --login "${REMOTE_USER}" -- "$@"
    else
        "$@"
    fi
}
```

Usage: `remote_user_do mkdir -p "${REMOTE_USER_HOME}/.local/bin"`

### `require_command` — assert a command is on PATH

```bash
require_command() {
    local cmd="$1"
    if ! command -v "${cmd}" > /dev/null 2>&1; then
        echo "ERROR: required command '${cmd}' not found" >&2
        exit 1
    fi
}
```

Usage: `require_command curl`

### `set_remote_ownership` — transfer ownership to the remote user

```bash
set_remote_ownership() {
    chown -R "${REMOTE_USER}:${REMOTE_USER}" "$@"
}
```

Usage: `set_remote_ownership /opt/mytool`

---

## Architecture Detection

```bash
ARCH="$(uname -m)"
case "${ARCH}" in
    x86_64)  ARCH="x86_64"  ;;
    aarch64) ARCH="aarch64" ;;
    arm64)   ARCH="aarch64" ;;   # macOS arm64 alias
    armv7l)  ARCH="armv7"   ;;
    *)
        echo "Unsupported architecture: ${ARCH}" >&2
        exit 1
        ;;
esac
```

---

## OS / Distro Detection

```bash
# shellcheck source=/dev/null
. /etc/os-release
OS_ID="${ID:-unknown}"
OS_ID_LIKE="${ID_LIKE:-}"

is_debian_family() {
    [[ "${OS_ID}" == "debian" || "${OS_ID}" == "ubuntu" || "${OS_ID_LIKE}" =~ debian ]]
}

is_fedora_family() {
    [[ "${OS_ID}" == "fedora" || "${OS_ID}" == "rhel" || "${OS_ID}" == "almalinux" \
        || "${OS_ID_LIKE}" =~ rhel || "${OS_ID_LIKE}" =~ fedora ]]
}

is_arch_linux() {
    [[ "${OS_ID}" == "arch" || "${OS_ID_LIKE}" =~ arch ]]
}

is_alpine() {
    [[ "${OS_ID}" == "alpine" ]]
}
```

---

## Environment Variable — profile.d Export

Writes a variable to `/etc/profile.d/` so it persists across login shells.

```bash
# add_env_to_profile VAR_NAME "value"
add_env_to_profile() {
    local var_name="$1"
    local var_value="$2"
    local profile_file="/etc/profile.d/${var_name,,}.sh"   # lowercase filename
    echo "export ${var_name}=\"${var_value}\"" > "${profile_file}"
    chmod 644 "${profile_file}"
}
```

Usage: `add_env_to_profile MY_TOOL_HOME "/opt/mytool"`

---

## Download and Extract a Tarball

```bash
# download_and_extract <url> <dest_dir>
# Streams the tarball directly; strips the top-level directory inside.
download_and_extract() {
    local url="$1"
    local dest="$2"
    mkdir -p "${dest}"
    curl -fsSL "${url}" | tar -xz -C "${dest}" --strip-components=1
}
```

---

## Shell Completion — Append to User RC Files

Appends a completion snippet to `.bashrc` and `.zshrc` only if not already present.
Must be called inside `remote_user_do` or run after the user's home is known.

```bash
# append_shell_snippet "eval \"\$(mytool completion bash)\""
append_shell_snippet() {
    local snippet="$1"
    local bashrc="${REMOTE_USER_HOME}/.bashrc"
    local zshrc="${REMOTE_USER_HOME}/.zshrc"

    if [ -f "${bashrc}" ] && ! grep -qF "${snippet}" "${bashrc}"; then
        printf '\n# Added by devcontainer feature\n%s\n' "${snippet}" >> "${bashrc}"
    fi
    if [ -f "${zshrc}" ] && ! grep -qF "${snippet}" "${zshrc}"; then
        printf '\n# Added by devcontainer feature\n%s\n' "${snippet}" >> "${zshrc}"
    fi
}
```

---

## Idempotency Guard

Prevents re-running expensive install steps when the tool is already present.

```bash
if command -v mytool > /dev/null 2>&1; then
    echo "mytool already installed: $(mytool --version)"
    exit 0
fi
```

---

## Minimal Package Install (distro-aware)

```bash
install_packages() {
    if is_debian_family; then
        apt-get install -y --no-install-recommends "$@"
    elif is_fedora_family; then
        dnf install -y "$@"
    elif is_arch_linux; then
        pacman -Sy --noconfirm "$@"
    elif is_alpine; then
        apk add --no-cache "$@"
    else
        echo "Unsupported distro: ${OS_ID}" >&2
        exit 1
    fi
}
```

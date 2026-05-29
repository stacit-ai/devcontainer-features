# Knowledge Base - install.sh Code Snippets

These snippets are small, self-contained Bash patterns for
`src/<name>/install.sh`. Copy only the pieces a feature actually needs.

---

## Script Header

Every `install.sh` starts with strict Bash mode:

```bash
#!/bin/bash
set -euo pipefail
```

---

## `remote_user_do`

Run a command as the devcontainer remote user. Use this when files or tool state
should belong to the final user, not root.

```bash
remote_user_do() {
    if [ -n "${_REMOTE_USER:-}" ] && [ "${_REMOTE_USER}" != "root" ]; then
        sudo -i -u "${_REMOTE_USER}" -- "$@"
    else
        "$@"
    fi
}
```

Example:

```bash
remote_user_do env HOME="${_REMOTE_USER_HOME}" my-tool install
```

---

## `require_command`

Fail fast when a required command is unavailable.

```bash
require_command() {
    local command="$1"

    if ! command -v "${command}" > /dev/null 2>&1; then
        echo "ERROR: required command '${command}' not found" >&2
        exit 1
    fi
}
```

Example:

```bash
require_command curl
```

---

## `set_remote_ownership`

Transfer one or more paths to the devcontainer remote user.

```bash
set_remote_ownership() {
    chown -R "${_REMOTE_USER}:${_REMOTE_USER}" "$@"
}
```

Example:

```bash
set_remote_ownership /opt/my-feature
```

---

## Dependency Installation

Only include package-manager branches for image families the feature explicitly
supports. If an image family is outside the feature design, fail instead of
silently skipping dependencies.

```bash
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

install_microdnf_deps() {
    microdnf install -y "$@"
    microdnf clean all
}

install_yum_deps() {
    yum install -y "$@"
}

detect_package_manager() {
    if command -v apt-get > /dev/null 2>&1; then
        echo apt
    elif command -v apk > /dev/null 2>&1; then
        echo apk
    elif command -v dnf > /dev/null 2>&1; then
        echo dnf
    elif command -v microdnf > /dev/null 2>&1; then
        echo microdnf
    elif command -v yum > /dev/null 2>&1; then
        echo yum
    else
        echo "ERROR: unsupported package manager for this feature" >&2
        exit 1
    fi
}

install_deps() {
    case "$(detect_package_manager)" in
        apt) install_apt_deps "$@" ;;
        apk) install_apk_deps "$@" ;;
        dnf) install_dnf_deps "$@" ;;
        microdnf) install_microdnf_deps "$@" ;;
        yum) install_yum_deps "$@" ;;
        *)
            echo "ERROR: unsupported package manager for this feature" >&2
            exit 1
            ;;
    esac
}
```

Example:

```bash
install_deps curl ca-certificates
```

#!/bin/bash
set -euo pipefail

CODEX_VERSION="${VERSION:-"latest"}"
CODEX_INSTALLER_URL="https://chatgpt.com/codex/install.sh"

install_codex() {
    echo "Installing Codex release: ${CODEX_VERSION}"
    mkdir -p /usr/local/share/codex
    curl -fsSL "${CODEX_INSTALLER_URL}" |
        CODEX_HOME=/usr/local/share/codex \
        CODEX_INSTALL_DIR=/usr/local/bin \
        CODEX_NON_INTERACTIVE=1 \
        sh -s -- --release "${CODEX_VERSION}"
}

install_sync_helper() {
    install -o root -g root -m 0755 auth-sync.sh /usr/local/lib/codex-auth-sync
}

configure_file_auth() {
    local remote_user="${_REMOTE_USER:-root}"

    mkdir -p /etc/codex
    printf '%s\n' "${remote_user}" > /etc/codex/remote-user
    chmod 0644 /etc/codex/remote-user

    touch /etc/codex/config.toml
    if ! grep -Eq '^[[:space:]]*cli_auth_credentials_store[[:space:]]*=' /etc/codex/config.toml; then
        printf '\ncli_auth_credentials_store = "file"\n' >> /etc/codex/config.toml
    fi
    chmod 0644 /etc/codex/config.toml
}

main() {
    install_codex
    install_sync_helper
    configure_file_auth
}

main "$@"

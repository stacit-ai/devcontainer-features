#!/bin/bash
set -e

source dev-container-features-test-lib

check "codex remains on PATH after duplicate install" codex --version
check "sync helper remains installed after duplicate install" test -x /usr/local/lib/codex-auth-sync
check "file auth default is not duplicated" bash -c "test \"$(grep -Ec '^[[:space:]]*cli_auth_credentials_store[[:space:]]*=' /etc/codex/config.toml)\" -eq 1"

reportResults

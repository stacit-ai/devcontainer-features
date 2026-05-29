#!/bin/bash
set -e

source dev-container-features-test-lib

check "test runs as remote user" bash -c "[ \"$(id -un)\" != root ]"

check "ruff binary is installed for remote user" test -x "${HOME}/.local/bin/ruff"
check "pytest binary is installed for remote user" test -x "${HOME}/.local/bin/pytest"
check "ty binary is installed for remote user" test -x "${HOME}/.local/bin/ty"
check "black binary is installed for remote user" test -x "${HOME}/.local/bin/black"
check "pyright binary is installed for remote user" test -x "${HOME}/.local/bin/pyright"
check "pre-commit binary is installed for remote user" test -x "${HOME}/.local/bin/pre-commit"
check "just binary is installed for remote user" test -x "${HOME}/.local/bin/just"

check "ruff is listed by remote user's uv tool list" bash -c "uv tool list | grep -Eq '^ruff( |$)'"
check "pytest is listed by remote user's uv tool list" bash -c "uv tool list | grep -Eq '^pytest( |$)'"
check "ty is listed by remote user's uv tool list" bash -c "uv tool list | grep -Eq '^ty( |$)'"
check "black is listed by remote user's uv tool list" bash -c "uv tool list | grep -Eq '^black( |$)'"
check "pyright is listed by remote user's uv tool list" bash -c "uv tool list | grep -Eq '^pyright( |$)'"
check "pre-commit is listed by remote user's uv tool list" bash -c "uv tool list | grep -Eq '^pre-commit( |$)'"
check "rust-just is listed by remote user's uv tool list" bash -c "uv tool list | grep -Eq '^rust-just( |$)'"

check "remote user can uninstall rust-just" bash -c "uv tool uninstall rust-just && ! uv tool list | grep -Eq '^rust-just( |$)'"

reportResults

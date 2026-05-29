#!/bin/bash
set -e

source dev-container-features-test-lib

check "uv is available" uv --version

check "ruff binary is absent" test ! -x "${HOME}/.local/bin/ruff"
check "pytest binary is absent" test ! -x "${HOME}/.local/bin/pytest"
check "ty binary is absent" test ! -x "${HOME}/.local/bin/ty"
check "black binary is absent" test ! -x "${HOME}/.local/bin/black"
check "pyright binary is absent" test ! -x "${HOME}/.local/bin/pyright"
check "pre-commit binary is absent" test ! -x "${HOME}/.local/bin/pre-commit"
check "just binary is absent" test ! -x "${HOME}/.local/bin/just"

check "ruff is absent from uv tool list" bash -c "! uv tool list | grep -Eq '^ruff( |$)'"
check "pytest is absent from uv tool list" bash -c "! uv tool list | grep -Eq '^pytest( |$)'"
check "ty is absent from uv tool list" bash -c "! uv tool list | grep -Eq '^ty( |$)'"
check "black is absent from uv tool list" bash -c "! uv tool list | grep -Eq '^black( |$)'"
check "pyright is absent from uv tool list" bash -c "! uv tool list | grep -Eq '^pyright( |$)'"
check "pre-commit is absent from uv tool list" bash -c "! uv tool list | grep -Eq '^pre-commit( |$)'"
check "rust-just is absent from uv tool list" bash -c "! uv tool list | grep -Eq '^rust-just( |$)'"

reportResults

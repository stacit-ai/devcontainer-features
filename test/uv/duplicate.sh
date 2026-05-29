#!/bin/bash
set -e

source dev-container-features-test-lib

check "uv is available after duplicate install" uv --version
check "uvx is available after duplicate install" uvx --version

check "ruff binary remains installed" test -x "${HOME}/.local/bin/ruff"
check "pytest binary remains installed" test -x "${HOME}/.local/bin/pytest"
check "ty binary remains installed" test -x "${HOME}/.local/bin/ty"
check "black binary remains installed" test -x "${HOME}/.local/bin/black"
check "pyright binary remains installed" test -x "${HOME}/.local/bin/pyright"
check "pre-commit binary remains installed" test -x "${HOME}/.local/bin/pre-commit"
check "just binary remains installed" test -x "${HOME}/.local/bin/just"

check "ruff remains listed by uv tool list" bash -c "uv tool list | grep -Eq '^ruff( |$)'"
check "pytest remains listed by uv tool list" bash -c "uv tool list | grep -Eq '^pytest( |$)'"
check "ty remains listed by uv tool list" bash -c "uv tool list | grep -Eq '^ty( |$)'"
check "black remains listed by uv tool list" bash -c "uv tool list | grep -Eq '^black( |$)'"
check "pyright remains listed by uv tool list" bash -c "uv tool list | grep -Eq '^pyright( |$)'"
check "pre-commit remains listed by uv tool list" bash -c "uv tool list | grep -Eq '^pre-commit( |$)'"
check "rust-just remains listed by uv tool list" bash -c "uv tool list | grep -Eq '^rust-just( |$)'"

reportResults

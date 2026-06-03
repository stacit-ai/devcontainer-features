#!/bin/bash
set -e

source dev-container-features-test-lib

check "zsh is available" zsh --version

current_user_login_shell_is_zsh() {
    getent passwd "$(whoami)" | cut -d: -f7 | grep -Eq '(^|/)zsh$'
}

check "current user login shell is zsh" current_user_login_shell_is_zsh
check "zsh can start and reports ZSH_VERSION" zsh -lc '[ -n "$ZSH_VERSION" ]'
check "uv is available from zsh" zsh -lc 'uv --version'
check "uvx is available from zsh" zsh -lc 'uvx --version'

check "ruff can be installed and run in a uv project from zsh" zsh -lc '
project="${PWD}/uv-ruff-project-zsh"
uv init "${project}"
cd "${project}"
uv add --dev ruff
uv run ruff --version
'

reportResults

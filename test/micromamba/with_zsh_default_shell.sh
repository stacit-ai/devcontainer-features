#!/bin/bash
set -e

source dev-container-features-test-lib

check "zsh is available" zsh --version
check "current user login shell is zsh" bash -c 'getent passwd "$(whoami)" | cut -d: -f7 | grep -Eq "(^|/)zsh$"'
check "zsh micromamba init block is present" bash -c 'grep -q "mamba initialize" "${HOME}/.zshrc"'
check "micromamba is available from zsh login shell" zsh -lc 'micromamba --version'
check "micromamba base environment is in remote user home from zsh" zsh -lc 'micromamba info | grep -Eq "base environment[[:space:]]*:[[:space:]]*${HOME}/micromamba"'

reportResults

#!/bin/bash
set -e

source dev-container-features-test-lib

check "zsh is available" zsh --version
check "current user login shell is zsh" bash -c 'getent passwd "$(whoami)" | cut -d: -f7 | grep -Eq "(^|/)zsh$"'
check "zsh conda init block is present" bash -c 'grep -q "conda initialize" "${HOME}/.zshrc"'
check "conda is available from zsh login shell" zsh -lc 'conda --version'
check "mamba is available from zsh login shell" zsh -lc 'mamba --version'
check "conda base is in remote user home from zsh" zsh -lc 'test "$(conda info --base)" = "${HOME}/.miniforge3"'

reportResults

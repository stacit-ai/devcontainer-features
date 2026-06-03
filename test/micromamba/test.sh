#!/bin/bash
set -e

source dev-container-features-test-lib

check "micromamba is available" micromamba --version
check "micromamba is executable in /usr/local/bin" test -x /usr/local/bin/micromamba
check "micromamba base environment is in remote user home" bash -c 'micromamba info | grep -Eq "base environment[[:space:]]*:[[:space:]]*${HOME}/micromamba"'
check "bash micromamba init block is present" bash -c 'grep -q "mamba initialize" "${HOME}/.bashrc"'
check "micromamba is available from bash login shell" bash -lc 'micromamba --version'

reportResults

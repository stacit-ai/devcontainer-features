#!/bin/bash
set -e

source dev-container-features-test-lib

check "micromamba is available without shell init" /usr/local/bin/micromamba --version
check "micromamba base environment is in remote user home without shell init" bash -c '/usr/local/bin/micromamba info | grep -Eq "base environment[[:space:]]*:[[:space:]]*${HOME}/micromamba"'
check "bash micromamba init block is absent" bash -c '! grep -q "mamba initialize" "${HOME}/.bashrc" 2>/dev/null'

reportResults

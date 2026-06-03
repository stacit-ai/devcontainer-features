#!/bin/bash
set -e

source dev-container-features-test-lib

check "conda symlink is available" /usr/local/bin/conda --version
check "mamba symlink is available" /usr/local/bin/mamba --version
check "conda base is in remote user home without shell init" bash -c 'test "$(/usr/local/bin/conda info --base)" = "${HOME}/.miniforge3"'
check "bash conda init block is absent" bash -c '! grep -q "conda initialize" "${HOME}/.bashrc" 2>/dev/null'

reportResults

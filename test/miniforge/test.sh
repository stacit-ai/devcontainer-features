#!/bin/bash
set -e

source dev-container-features-test-lib

check "conda is available" conda --version
check "mamba is available" mamba --version
check "conda base is in remote user home" bash -c 'test "$(conda info --base)" = "${HOME}/.miniforge3"'
check "bash conda init block is present" bash -c 'grep -q "conda initialize" "${HOME}/.bashrc"'
check "conda is available from bash login shell" bash -lc 'conda --version'

reportResults

#!/bin/bash
set -e

source dev-container-features-test-lib

check "conda is available with pinned Miniforge version" conda --version
check "mamba is available with pinned Miniforge version" mamba --version
check "conda base is in remote user home with pinned Miniforge version" bash -c 'test "$(conda info --base)" = "${HOME}/.miniforge3"'

reportResults

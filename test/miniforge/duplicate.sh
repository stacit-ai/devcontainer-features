#!/bin/bash
set -e

source dev-container-features-test-lib

check "conda is available after duplicate install" conda --version
check "mamba is available after duplicate install" mamba --version
check "conda base is in remote user home after duplicate install" bash -c 'test "$(conda info --base)" = "${HOME}/.miniforge3"'

reportResults

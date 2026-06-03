#!/bin/bash
set -e

source dev-container-features-test-lib

check "micromamba is available with pinned version" micromamba --version
check "micromamba base environment is in remote user home with pinned version" bash -c 'micromamba info | grep -Eq "base environment[[:space:]]*:[[:space:]]*${HOME}/micromamba"'

reportResults

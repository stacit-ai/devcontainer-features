#!/bin/bash
set -e

source dev-container-features-test-lib

check "micromamba is available after duplicate install" micromamba --version
check "micromamba is executable in /usr/local/bin after duplicate install" test -x /usr/local/bin/micromamba
check "micromamba base environment is in remote user home after duplicate install" bash -c 'micromamba info | grep -Eq "base environment[[:space:]]*:[[:space:]]*${HOME}/micromamba"'

reportResults

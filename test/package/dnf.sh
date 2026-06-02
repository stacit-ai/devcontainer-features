#!/bin/bash
set -e

source dev-container-features-test-lib

check "jq is available on dnf image" jq --version
check "curl is available on dnf image" curl --version
check "tree is available on dnf image" tree --version
check "zip is available on dnf image" zip --version

reportResults

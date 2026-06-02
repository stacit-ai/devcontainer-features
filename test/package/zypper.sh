#!/bin/bash
set -e

source dev-container-features-test-lib

check "jq is available on zypper image" jq --version
check "curl is available on zypper image" curl --version
check "tree is available on zypper image" tree --version
check "zip is available on zypper image" zip --version

reportResults

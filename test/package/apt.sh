#!/bin/bash
set -e

source dev-container-features-test-lib

check "jq is available on apt image" jq --version
check "curl is available on apt image" curl --version
check "tree is available on apt image" tree --version
check "zip is available on apt image" zip --version

reportResults

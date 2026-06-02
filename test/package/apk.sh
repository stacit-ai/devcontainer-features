#!/bin/bash
set -e

source dev-container-features-test-lib

check "jq is available on apk image" jq --version
check "curl is available on apk image" curl --version
check "tree is available on apk image" tree --version
check "zip is available on apk image" zip --version

reportResults

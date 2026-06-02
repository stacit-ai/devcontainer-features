#!/bin/bash
set -e

source dev-container-features-test-lib

check "jq is available on yum image through dnf option" jq --version
check "curl is available on yum image through dnf option" curl --version
check "tree is available on yum image through dnf option" tree --version
check "zip is available on yum image through dnf option" zip --version

reportResults

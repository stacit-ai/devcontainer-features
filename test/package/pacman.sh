#!/bin/bash
set -e

source dev-container-features-test-lib

check "jq is available on pacman image" jq --version
check "curl is available on pacman image" curl --version
check "tree is available on pacman image" tree --version
check "zip is available on pacman image" zip --version

reportResults

#!/bin/bash
set -e

source dev-container-features-test-lib

check "llama-server is available with pinned version" command -v llama-server
check "llama-cli is available with pinned version" command -v llama-cli
check "pinned version is recorded" grep -Fx "b9360" /usr/local/share/llama-cpp-feature/version

reportResults

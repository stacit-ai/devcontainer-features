#!/bin/bash
set -e

source dev-container-features-test-lib

check "llama-server is available" command -v llama-server
check "llama-cli is available" command -v llama-cli
check "llama-server help works" llama-server --help
check "llama-cli help works" llama-cli --help
check "default backend metadata is recorded" grep -Fx "cpu" /usr/local/share/llama-cpp-feature/backend
check "asset metadata is recorded" bash -c '[ -s /usr/local/share/llama-cpp-feature/asset ]'

reportResults

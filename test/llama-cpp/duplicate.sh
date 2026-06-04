#!/bin/bash
set -e

source dev-container-features-test-lib

check "llama-server is available after duplicate install" command -v llama-server
check "llama-cli is available after duplicate install" command -v llama-cli
check "llama-server help works after duplicate install" llama-server --help
check "llama-cli help works after duplicate install" llama-cli --help
check "default backend metadata is recorded after duplicate install" grep -Fx "cpu" /usr/local/share/llama-cpp-feature/backend

reportResults

#!/bin/bash
set -e

source dev-container-features-test-lib

check "llama-server is available with vulkan backend" command -v llama-server
check "llama-cli is available with vulkan backend" command -v llama-cli
check "vulkan backend is recorded" grep -Fx "vulkan" /usr/local/share/llama-cpp-feature/backend
check "vulkan asset is recorded" grep -E "ubuntu-vulkan-.*\\.tar\\.gz" /usr/local/share/llama-cpp-feature/asset

reportResults

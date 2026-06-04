#!/bin/bash
set -e

source dev-container-features-test-lib

check "ollama is available with pinned version" command -v ollama
check "ollama version works with pinned version" ollama --version
check "pinned version is recorded" grep -Fx "0.5.7" /usr/local/share/ollama-feature/version

reportResults

#!/bin/bash
set -e

source dev-container-features-test-lib

check "ollama is available after duplicate install" command -v ollama
check "ollama version works after duplicate install" ollama --version
check "OLLAMA_MODELS is configured after duplicate install" bash -c '[ "${OLLAMA_MODELS}" = "/opt/ollama/models" ]'
check "OLLAMA_MODELS directory is writable after duplicate install" bash -c 'touch /opt/ollama/models/.write-test-duplicate'

reportResults

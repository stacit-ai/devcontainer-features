#!/bin/bash
set -e

source dev-container-features-test-lib

check "hf is available after duplicate install" hf --help
check "HF_HOME is configured after duplicate install" bash -c '[ "${HF_HOME}" = "/opt/huggingface" ]'
check "huggingface_hub HF_HOME follows environment after duplicate install" uvx --from huggingface_hub python -c 'from huggingface_hub import constants; assert constants.HF_HOME == "/opt/huggingface", constants.HF_HOME'
check "huggingface_hub cache is derived from HF_HOME after duplicate install" uvx --from huggingface_hub python -c 'from huggingface_hub import constants; assert constants.HF_HUB_CACHE == "/opt/huggingface/hub", constants.HF_HUB_CACHE'
check "HF_HOME is writable after duplicate install" bash -c 'touch /opt/huggingface/.write-test-duplicate'

reportResults

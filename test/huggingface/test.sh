#!/bin/bash
set -e

source dev-container-features-test-lib

check "hf is available" hf --help
check "HF_HOME is configured" bash -c '[ "${HF_HOME}" = "/opt/huggingface" ]'
check "huggingface_hub HF_HOME follows environment" uvx --from huggingface_hub python -c 'from huggingface_hub import constants; assert constants.HF_HOME == "/opt/huggingface", constants.HF_HOME'
check "huggingface_hub cache is derived from HF_HOME" uvx --from huggingface_hub python -c 'from huggingface_hub import constants; assert constants.HF_HUB_CACHE == "/opt/huggingface/hub", constants.HF_HUB_CACHE'
check "HF_HOME is writable" bash -c 'touch /opt/huggingface/.write-test'

reportResults

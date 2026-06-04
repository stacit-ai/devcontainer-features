#!/bin/bash
set -e

source dev-container-features-test-lib

check "hf-mount is available with pinned version" command -v hf-mount
check "hf-mount-nfs is available with pinned version" command -v hf-mount-nfs
check "pinned version is recorded" grep -Fx "v0.6.5" /usr/local/share/hf-mount-feature/version

reportResults

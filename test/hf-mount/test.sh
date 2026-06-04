#!/bin/bash
set -e

source dev-container-features-test-lib

check "hf-mount is available" command -v hf-mount
check "hf-mount-nfs is available" command -v hf-mount-nfs
check "hf-mount help works" hf-mount --help
check "hf-mount-nfs help works" hf-mount-nfs --help

reportResults

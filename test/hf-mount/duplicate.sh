#!/bin/bash
set -e

source dev-container-features-test-lib

check "hf-mount is available after duplicate install" command -v hf-mount
check "hf-mount-nfs is available after duplicate install" command -v hf-mount-nfs
check "hf-mount help works after duplicate install" hf-mount --help
check "hf-mount-nfs help works after duplicate install" hf-mount-nfs --help

reportResults

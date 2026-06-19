#!/bin/bash
set -e

source dev-container-features-test-lib

check "requested Codex version is installed" bash -c "codex --version | grep -F '0.140.0'"

reportResults

#!/bin/bash
set -e

source dev-container-features-test-lib

check "curl is available after duplicate install" curl --version

reportResults

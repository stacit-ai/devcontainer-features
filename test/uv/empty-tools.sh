#!/bin/bash
# Scenario: toolsToInstall="" — verifies uv is present but no tools are installed.
set -euo pipefail

# shellcheck source=/dev/null
. /etc/profile.d/uv.sh

# ---------------------------------------------------------------------------
# uv binary must be present
# ---------------------------------------------------------------------------
if ! command -v uv > /dev/null 2>&1; then
    echo "FAIL: 'uv' not found on PATH"
    exit 1
fi
echo "PASS: uv on PATH — $(uv --version)"

# ---------------------------------------------------------------------------
# Tool binaries must NOT be present (empty toolsToInstall)
# ---------------------------------------------------------------------------
DEFAULT_TOOLS="ruff pytest ty black pyright pre-commit just"
for tool in ${DEFAULT_TOOLS}; do
    bin="/usr/local/share/uv/bin/${tool}"
    if [ -x "${bin}" ]; then
        echo "FAIL: ${bin} exists but toolsToInstall was empty"
        exit 1
    fi
    echo "PASS: ${tool} correctly absent"
done

echo ""
echo "All empty-tools scenario tests passed."

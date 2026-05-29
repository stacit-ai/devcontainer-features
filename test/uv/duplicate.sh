#!/bin/bash
# Idempotency test: run after feature has already been installed.
# Verifies that a second install does not break anything.
set -euo pipefail

# shellcheck source=/dev/null
. /etc/profile.d/uv.sh

# ---------------------------------------------------------------------------
# uv binary still accessible
# ---------------------------------------------------------------------------
if ! command -v uv > /dev/null 2>&1; then
    echo "FAIL: 'uv' not found on PATH after duplicate install"
    exit 1
fi
echo "PASS: uv on PATH — $(uv --version)"

# ---------------------------------------------------------------------------
# uvx binary still accessible
# ---------------------------------------------------------------------------
if ! command -v uvx > /dev/null 2>&1; then
    echo "FAIL: 'uvx' not found on PATH after duplicate install"
    exit 1
fi
echo "PASS: uvx on PATH — $(uvx --version)"

# ---------------------------------------------------------------------------
# Default tools still present
# ---------------------------------------------------------------------------
DEFAULT_TOOLS="ruff pytest ty black pyright pre-commit just"
for tool in ${DEFAULT_TOOLS}; do
    bin="/usr/local/share/uv/bin/${tool}"
    if [ ! -x "${bin}" ]; then
        echo "FAIL: ${bin} not found after duplicate install"
        exit 1
    fi
    echo "PASS: ${tool} still present after duplicate install"
done

echo ""
echo "All duplicate-install tests passed."

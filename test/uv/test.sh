#!/bin/bash
set -euo pipefail

# shellcheck source=/dev/null
. /etc/profile.d/uv.sh

# ---------------------------------------------------------------------------
# 1. uv binary on PATH
# ---------------------------------------------------------------------------
if ! command -v uv > /dev/null 2>&1; then
    echo "FAIL: 'uv' not found on PATH"
    exit 1
fi
echo "PASS: uv on PATH — $(uv --version)"

# ---------------------------------------------------------------------------
# 2. uvx binary on PATH
# ---------------------------------------------------------------------------
if ! command -v uvx > /dev/null 2>&1; then
    echo "FAIL: 'uvx' not found on PATH"
    exit 1
fi
echo "PASS: uvx on PATH — $(uvx --version)"

# ---------------------------------------------------------------------------
# 3. UV_* environment variables are set
# ---------------------------------------------------------------------------
check_env() {
    local var="$1"
    local expected="$2"
    local actual="${!var:-}"
    if [ "${actual}" != "${expected}" ]; then
        echo "FAIL: ${var}='${actual}' (expected '${expected}')"
        exit 1
    fi
    echo "PASS: ${var}=${actual}"
}

check_env UV_PYTHON_INSTALL_DIR "/opt/uv/python"
check_env UV_CACHE_DIR          "/opt/uv/cache"
check_env UV_PROJECT_ENVIRONMENT "/opt/uv/venv"
check_env UV_TOOL_DIR            "/usr/local/share/uv/tools"
check_env UV_TOOL_BIN_DIR        "/usr/local/share/uv/bin"

# ---------------------------------------------------------------------------
# 4. /usr/local/share/uv/bin is on PATH
# ---------------------------------------------------------------------------
if [[ ":${PATH}:" != *":/usr/local/share/uv/bin:"* ]]; then
    echo "FAIL: /usr/local/share/uv/bin is not on PATH (PATH=${PATH})"
    exit 1
fi
echo "PASS: /usr/local/share/uv/bin is on PATH"

# ---------------------------------------------------------------------------
# 5. Default tools are installed and executable
# ---------------------------------------------------------------------------
DEFAULT_TOOLS="ruff pytest ty black pyright pre-commit just"
for tool in ${DEFAULT_TOOLS}; do
    bin="/usr/local/share/uv/bin/${tool}"
    if [ ! -x "${bin}" ]; then
        echo "FAIL: ${bin} not found or not executable"
        exit 1
    fi
    echo "PASS: ${tool} installed — $("${bin}" --version 2>&1 | head -1)"
done

echo ""
echo "All tests passed."

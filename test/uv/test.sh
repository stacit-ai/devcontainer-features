#!/bin/bash
set -e

source dev-container-features-test-lib

check "uv is available" uv --version
check "uvx is available" uvx --version

init_project_and_install_ruff() {
    project="${PWD}/uv-ruff-project-default"
    uv init "${project}"
    cd "${project}"
    uv add --dev ruff
    uv run ruff --version
}

check "ruff can be installed and run in a uv project" init_project_and_install_ruff

reportResults

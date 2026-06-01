#!/bin/bash
set -e

source dev-container-features-test-lib

check "uv is available with python feature" uv --version
check "uvx is available with python feature" uvx --version

check "pre-commit is available with python feature" pre-commit --version

init_project_and_install_ruff() {
    project="${PWD}/uv-ruff-project-python-feature"
    uv init "${project}"
    cd "${project}"
    uv add --dev ruff
    uv run ruff --version
}

check "ruff can be installed and run in a uv project with python feature" init_project_and_install_ruff

reportResults

#!/bin/bash
set -euo pipefail

HF_HOME_DIR="/opt/huggingface"

main() {
    mkdir -p "${HF_HOME_DIR}"
    chmod o+rwX "${HF_HOME_DIR}"

    echo "==> huggingface feature configured HF_HOME at ${HF_HOME_DIR}."
}

main "$@"

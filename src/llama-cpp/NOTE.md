# llama.cpp feature notes

## Backend choices

Set the `backend` option to one of:

- `cpu`
- `vulkan`
- `cuda`
- `rocm`
- `openvino`

The default is `cpu`. GPU backends require matching runtime libraries and host
drivers from the base image or container runtime.

Backend availability can vary by llama.cpp release and CPU architecture. Before
pinning a backend, check that the selected release has a matching Ubuntu asset,
such as `ubuntu-x64`, `ubuntu-arm64`, `ubuntu-vulkan-x64`,
`ubuntu-rocm-<version>-x64`, or `ubuntu-openvino-<version>-x64`.

## Version choices

Set the `version` option to `latest` or to a llama.cpp release tag such as
`b9360`.

Available version tags are listed on the llama.cpp releases page:

https://github.com/ggml-org/llama.cpp/releases


# llama.cpp (llama-cpp)

Installs llama.cpp prebuilt binaries, including llama-server, for local LLM serving.

## Example Usage

```json
"features": {
    "ghcr.io/stacit-ai/devcontainer-features/llama-cpp:1": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| version | llama.cpp GitHub release tag to install. Use 'latest' for the current release, or a tag such as 'b9360'. | string | latest |
| backend | Upstream prebuilt backend to install. GPU backends require matching runtime libraries and drivers from the base image or host. | string | cpu |

# llama.cpp feature notes

## Compatibility

Use this feature only with Ubuntu container images. The feature installs
upstream llama.cpp Ubuntu binaries, so Debian, Fedora, AlmaLinux, Arch,
openSUSE, Alpine, and other non-Ubuntu images are not supported.

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


---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/stacit-ai/devcontainer-features/blob/main/src/llama-cpp/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._

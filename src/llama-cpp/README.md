
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



---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/stacit-ai/devcontainer-features/blob/main/src/llama-cpp/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._

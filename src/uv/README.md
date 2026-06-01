
# uv (uv)

Installs uv — an extremely fast Python package and project manager. Centralises Python interpreter and package caches under a named Docker volume for faster rebuilds.

## Example Usage

```json
"features": {
    "ghcr.io/stacit-ai/devcontainer-features/uv:1": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| version | Version of uv to install (e.g. '0.11.17'). Use 'latest' for the current release. | string | latest |
| toolsToInstall | Comma-separated list of CLI tools to install with uv tool install. Set to empty string to skip tool installation. | string | - |



---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/stacit-ai/devcontainer-features/blob/main/src/uv/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._

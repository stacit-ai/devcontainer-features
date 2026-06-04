
# Miniforge (miniforge)

Installs Miniforge for the remote user and optionally initializes conda for the user's shell.

## Example Usage

```json
"features": {
    "ghcr.io/stacit-ai/devcontainer-features/miniforge:1": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| version | Miniforge GitHub release tag to install (e.g. '26.3.2-2'). Use 'latest' for the current release. | string | latest |
| initShell | Shell to initialize with conda init. Use 'auto' to detect the remote user's login shell, or 'none' to skip initialization. | string | auto |



---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/stacit-ai/devcontainer-features/blob/main/src/miniforge/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._

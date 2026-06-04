
# micromamba (micromamba)

Installs the micromamba executable and optionally initializes it for the remote user's shell.

## Example Usage

```json
"features": {
    "ghcr.io/stacit-ai/devcontainer-features/micromamba:1": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| version | micromamba release/build tag to install (e.g. '2.7.0-0'). Use 'latest' for the current release. | string | latest |
| initShell | Shell to initialize with micromamba shell init. Use 'auto' to detect the remote user's login shell, or 'none' to skip initialization. | string | auto |



---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/stacit-ai/devcontainer-features/blob/main/src/micromamba/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._

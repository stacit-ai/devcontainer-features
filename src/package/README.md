
# Package (package)

Installs system dependency packages across apt, dnf/yum, apk, pacman, and zypper based images.

## Example Usage

```json
"features": {
    "ghcr.io/stacit-ai/devcontainer-features/package:1": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| package | Comma-separated list of packages to install on every supported system. | string | - |
| apt | Comma-separated list of packages to install when apt-get is detected. | string | - |
| dnf | Comma-separated list of packages to install when dnf or yum is detected. | string | - |
| apk | Comma-separated list of packages to install when apk is detected. | string | - |
| pacman | Comma-separated list of packages to install when pacman is detected. | string | - |
| zypper | Comma-separated list of packages to install when zypper is detected. | string | - |



---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/stacit-ai/devcontainer-features/blob/main/src/package/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._

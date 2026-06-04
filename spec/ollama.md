# Feature Spec: ollama

## Goals

Install [Ollama](https://ollama.com/) for local LLM serving inside a
devcontainer. The feature:

1. Places the `ollama` CLI on the system `PATH`.
2. Sets `OLLAMA_MODELS` to `/opt/ollama/models`.
3. Backs `/opt/ollama/models` with a named Docker volume so downloaded models
   survive devcontainer rebuilds.
4. Supports default latest installs and explicit version pinning.

This feature is install-only. Users start the server at runtime with
`ollama serve`; the feature does not create a systemd service, install GPU
drivers, or download models.

---

## Supported Platforms

| Platform | Status |
|---|---|
| Linux x86_64 | supported |
| Linux aarch64 | supported |
| Debian / Ubuntu (apt) | supported |
| RHEL / AlmaLinux / Fedora (dnf/yum) | supported |
| Arch Linux (pacman) | supported |
| openSUSE (zypper) | supported |
| Alpine (apk / musl) | not supported |

The supported Linux platforms match the upstream Ollama Linux bundles.

---

## Options

| Option | Type | Default | Description |
|---|---|---|---|
| `version` | string | `"latest"` | Ollama version to install. Use `"latest"` for the current download, or a version such as `"0.5.7"` / `"v0.5.7"` for a pinned release. |

---

## Directory Layout

```
/opt/ollama/models/        <- OLLAMA_MODELS and named Docker volume mount point
```

---

## Implementation Notes / Gotchas

- The feature downloads and extracts the official Linux bundle. It intentionally
  avoids the official install script's systemd service and GPU driver setup.
- The installer supports upstream `.tar.zst` bundles and falls back to `.tgz`
  for older versions.
- `OLLAMA_MODELS` is fixed to `/opt/ollama/models` in v1.
- The feature does not run `ollama serve`, pull models, or read credentials.
- GPU runtime support is provided by the base image or host container runtime,
  not by this feature.

---

## External References

- Linux installation: <https://docs.ollama.com/linux>
- Install script: <https://raw.githubusercontent.com/ollama/ollama/refs/heads/main/scripts/install.sh>

---

## TDD Behavior Backlog (implementation order)

1. `ollama` binary is on `PATH` after install
2. `ollama --version` executes without starting the server
3. `OLLAMA_MODELS` is set to `/opt/ollama/models`
4. `/opt/ollama/models` is writable
5. `ollama serve` starts successfully in the test container
6. `ollama run smollm2:135m` completes a minimal smoke prompt
7. `smollm2:135m` is cached under `/opt/ollama/models` with its manifest and
   blob files
8. Specific `version` option records the requested version
9. Re-install is idempotent

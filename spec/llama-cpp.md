# Feature Spec: llama-cpp

## Goals

Install [llama.cpp](https://github.com/ggml-org/llama.cpp) prebuilt binaries
for local LLM serving inside a devcontainer. The feature:

1. Places `llama-server` on the system `PATH`.
2. Places `llama-cli` on the system `PATH`.
3. Supports default latest-release installs and explicit release pinning.
4. Supports selecting an upstream prebuilt backend when an asset exists.

This feature is install-only. Users provide models and start the server at
runtime with `llama-server`.

---

## Supported Platforms

| Platform | Status |
|---|---|
| Linux x86_64, CPU backend | supported |
| Linux aarch64, CPU backend | supported |
| Linux x86_64 / aarch64, Vulkan backend | supported when upstream asset exists |
| Linux x86_64, ROCm backend | supported when upstream asset exists |
| Linux x86_64, OpenVINO backend | supported when upstream asset exists |
| Linux x86_64, CUDA backend | proposal only; supported when upstream Linux CUDA asset exists |
| Alpine (apk / musl) | not supported |

The feature downloads upstream Ubuntu release assets. GPU backends require the
matching runtime libraries and drivers to be provided by the base image or host
container runtime.

---

## Options

| Option | Type | Default | Description |
|---|---|---|---|
| `version` | string | `"latest"` | llama.cpp release tag to install. Use `"latest"` for GitHub's latest release, or a tag such as `"b9360"` for a pinned release. |
| `backend` | string | `"cpu"` | Upstream prebuilt backend to install. |

---

## Implementation Notes / Gotchas

- The installer resolves `"latest"` through the GitHub releases API.
- Asset names include the release tag and backend-specific suffixes. The
  installer searches the resolved release's assets and fails clearly when the
  requested backend/architecture has no asset.
- Only `llama-server` and `llama-cli` are installed in v1.
- The feature does not build from source, install GPU drivers, install CUDA or
  ROCm runtime packages, download models, or create a service.
- The `cuda` backend is included in proposals, but upstream Linux CUDA assets
  may not exist for a given release.

---

## External References

- README: <https://raw.githubusercontent.com/ggml-org/llama.cpp/refs/heads/master/README.md>
- Install docs: <https://raw.githubusercontent.com/ggml-org/llama.cpp/refs/heads/master/docs/install.md>
- Build docs: <https://raw.githubusercontent.com/ggml-org/llama.cpp/refs/heads/master/docs/build.md>
- GitHub releases: <https://github.com/ggml-org/llama.cpp/releases>

---

## TDD Behavior Backlog (implementation order)

1. `llama-server` binary is on `PATH` after install
2. `llama-cli` binary is on `PATH` after install
3. `llama-server --help` executes without a model
4. `llama-cli --help` executes without a model
5. Install metadata records resolved version tag, backend, and asset
6. Specific `version` option records the requested upstream release tag
7. Non-default backend option records the requested backend
8. Re-install is idempotent

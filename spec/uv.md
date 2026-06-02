# Feature Spec: uv

## Goals

Install [uv](https://docs.astral.sh/uv/), an extremely fast Python package and
project manager written in Rust.  The feature:

1. Places the `uv` and `uvx` binaries on the system `PATH`.
2. Centralises all uv state that benefits from caching under `/opt/uv/`, bound
   to a named Docker volume so Python interpreters and download caches survive
   devcontainer rebuilds.
3. Optionally installs selected CLI tools during feature install via
  `uv tool install`.

---

## Supported Platforms

| Image family | Status |
|---|---|
| Debian / Ubuntu (apt) | ✅ supported |
| RHEL / AlmaLinux (dnf) | ✅ supported |
| Arch Linux (pacman) | ✅ supported |
| Alpine (apk) | ✅ supported |
| openSUSE (zypper) | ✅ supported |
| `mcr.microsoft.com/devcontainers/base:*` | ✅ supported |

---

## Options

| Option | Type | Default | Description |
|---|---|---|---|
| `version` | string | `"latest"` | uv version to install (e.g. `"0.6.0"`). `"latest"` resolves to the current release. |
| `toolsToInstall` | string | `""` | Comma-separated list of tools to install with `uv tool install` (e.g. `"pytest,ty"`). Empty string skips tool installation. |

---

## Directory Layout

```
/usr/local/bin/uv          ← uv binary (system-wide, in image layer)
/usr/local/bin/uvx         ← uvx binary (system-wide, in image layer)

/opt/uv/                   ← volume mount point (uv-${devcontainerId})
  python/                  ← UV_PYTHON_INSTALL_DIR  (Python interpreter cache)
  cache/                   ← UV_CACHE_DIR           (package download cache)
  venv/                    ← UV_PROJECT_ENVIRONMENT (shared project venv)

~/.local/bin/              ← uv and uvx executable directory
```

### Volume Strategy

`/opt/uv/` is declared as a named Docker volume (`uv-${devcontainerId}`).
Volumes are mounted at **container start**, not during image build.  The
feature only installs tools when `toolsToInstall` is non-empty.

The feature pre-creates `/opt/uv/python`, `/opt/uv/cache`, and `/opt/uv/venv`
during image build.  Docker uses that directory skeleton to initialize the
named volume.  Because devcontainer tooling can adjust the remote user's UID
between build and runtime, those runtime-writable directories are made
world-writable after creation.  This keeps uv-generated cache files such as
`CACHEDIR.TAG` writable after the named volume is mounted.

The volume provides caching for expensive operations:
- `UV_PYTHON_INSTALL_DIR` — avoids re-downloading Python interpreters
- `UV_CACHE_DIR` — avoids re-downloading packages on rebuild
- `UV_PROJECT_ENVIRONMENT` — preserves shared project virtual environments

---

## Runtime Environment

Runtime variables are declared in `devcontainer-feature.json` via
`containerEnv`:

```
UV_PYTHON_INSTALL_DIR=/opt/uv/python
UV_CACHE_DIR=/opt/uv/cache
UV_PROJECT_ENVIRONMENT=/opt/uv/venv
```

The feature does not set `UV_TOOL_DIR` or `UV_TOOL_BIN_DIR`.  Users can run
`uv tool install` after container creation to manage tools through uv's
defaults.

---

## Implementation Notes / Gotchas

- **uv installer accepts `UV_UNMANAGED_INSTALL`.** Setting this env var
  installs the binary to the given path and disables uv's self-update
  mechanism — appropriate for managed environments like devcontainers.
  Pass `UV_VERSION` alongside for version pinning.

- **Alpine uses musl libc.** uv distributes musl builds; the official
  installer handles arch/libc detection automatically.

- **System dependencies are delegated to `package`.** The uv feature depends on
  `ghcr.io/stacit-ai/devcontainer-features/package:1` to install `curl`,
  `ca-certificates`, and `sudo` across supported image families.

---

## External References

- Installation: <https://docs.astral.sh/uv/getting-started/installation/>
- Tools concept: <https://docs.astral.sh/uv/concepts/tools/>
- Environment variables: <https://docs.astral.sh/uv/reference/environment/>
- GitHub releases: <https://github.com/astral-sh/uv/releases>

---

## TDD Behavior Backlog (implementation order)

1. `uv` binary is on `PATH` after install (`uv --version` exits 0)
2. `uvx` binary is on `PATH` after install (`uvx --version` exits 0)
3. `UV_PYTHON_INSTALL_DIR` is set to `/opt/uv/python` in login environment
4. `UV_CACHE_DIR` is set to `/opt/uv/cache`
5. `UV_PROJECT_ENVIRONMENT` is set to `/opt/uv/venv`
6. Default Python tools are not pre-installed by the feature
7. A workspace project can add `ruff` as a development dependency and run it
   with `uv run ruff --version`
8. Re-install is idempotent (second install exits 0, `uv --version` works)
9. Specific `version` option installs that exact version

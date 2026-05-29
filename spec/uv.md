# Feature Spec: uv

## Goals

Install [uv](https://docs.astral.sh/uv/), an extremely fast Python package and
project manager written in Rust.  The feature:

1. Places the `uv` and `uvx` binaries on the system `PATH`.
2. Centralises all uv state that benefits from caching under `/opt/uv/`, bound
   to a named Docker volume so Python interpreters and download caches survive
   devcontainer rebuilds.
3. Optionally pre-installs a configurable list of global Python tools via
   `uv tool install`, so users can manage them later with `uv tool list` and
   `uv tool uninstall`.

---

## Supported Platforms

| Image family | Status |
|---|---|
| Debian / Ubuntu (apt) | ✅ supported |
| RHEL / AlmaLinux (dnf) | ✅ supported |
| Arch Linux (pacman) | ✅ supported |
| Alpine (apk) | ✅ supported |
| `mcr.microsoft.com/devcontainers/base:*` | ✅ supported |

---

## Options

| Option | Type | Default | Description |
|---|---|---|---|
| `version` | string | `"latest"` | uv version to install (e.g. `"0.6.0"`). `"latest"` resolves to the current release. |
| `toolsToInstall` | string | `"ruff,pytest,ty,black,pyright,pre-commit,rust-just"` | Comma-separated list of tools to install via `uv tool install`. Set to `""` to skip tool installation. |

---

## Directory Layout

```
/usr/local/bin/uv          ← uv binary (system-wide, in image layer)
/usr/local/bin/uvx         ← uvx binary (system-wide, in image layer)

/opt/uv/                   ← volume mount point (uv-${devcontainerId})
  python/                  ← UV_PYTHON_INSTALL_DIR  (Python interpreter cache)
  cache/                   ← UV_CACHE_DIR           (package download cache)
  venv/                    ← UV_PROJECT_ENVIRONMENT (shared project venv)

~/.local/share/uv/tools/   ← remote user's default uv tool storage
~/.local/bin/              ← remote user's default uv tool executable directory
```

### Volume Strategy

`/opt/uv/` is declared as a named Docker volume (`uv-${devcontainerId}`).
Volumes are mounted at **container start**, not during image build.  Tools
pre-installed by `install.sh` are installed as the remote user, using uv's
default user tool directories.  They are not written to `/opt/uv/`.

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

The feature does not set `UV_TOOL_DIR`, `UV_TOOL_BIN_DIR`, or `PATH`.  Running
`uv tool install` as the remote user lets `uv tool list` and
`uv tool uninstall` manage the pre-installed tools through uv's defaults.

---

## Implementation Notes / Gotchas

- **Install tools as the remote user.** Do not set global `UV_TOOL_DIR` or
  `UV_TOOL_BIN_DIR` for tool installation.  Use uv's default per-user tool
  directories so the remote user can manage pre-installed tools normally.

- **uv installer accepts `UV_UNMANAGED_INSTALL`.** Setting this env var
  installs the binary to the given path and disables uv's self-update
  mechanism — appropriate for managed environments like devcontainers.
  Pass `UV_VERSION` alongside for version pinning.

- **Alpine uses musl libc.** uv distributes musl builds; the official
  installer handles arch/libc detection automatically.

- **Package managers are explicit.** Dependency installation fails for package
  managers outside the feature's supported image families instead of silently
  skipping prerequisites.

- **`toolsToInstall` parsing:** split on `,`, trim whitespace around each
  entry, skip empty entries.

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
6. All default tools (ruff, pytest, ty, black, pyright, pre-commit, rust-just)
   are installed under the remote user's uv tool state
7. Default tools are visible through `uv tool list`
8. Default tools can be removed by the remote user with `uv tool uninstall`
9. Non-root remote users receive tools in their own uv tool state
10. `toolsToInstall=""` skips tool installation (no binaries present)
11. Re-install is idempotent (second install exits 0, `uv --version` works)
12. Specific `version` option installs that exact version

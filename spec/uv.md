# Feature Spec: uv

## Goals

Install [uv](https://docs.astral.sh/uv/), an extremely fast Python package and
project manager written in Rust.  The feature:

1. Places the `uv` and `uvx` binaries on the system `PATH`.
2. Centralises all uv state that benefits from caching under `/opt/uv/`, bound
   to a named Docker volume so Python interpreters and download caches survive
   devcontainer rebuilds.
3. Optionally pre-installs a configurable list of global Python tools via
   `uv tool install`.

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

/usr/local/share/uv/       ← tool storage (image layer, always accessible)
  tools/                   ← UV_TOOL_DIR
  bin/                     ← UV_TOOL_BIN_DIR  (added to PATH)
```

### Volume Strategy

`/opt/uv/` is declared as a named Docker volume (`uv-${devcontainerId}`).
Volumes are mounted at **container start**, not during image build.  Tools
pre-installed by `install.sh` must therefore live **outside** `/opt/uv/` —
otherwise the volume mount would hide them at runtime.  Tool binaries are
stored in `/usr/local/share/uv/` (image layer), which is always visible.

The volume provides caching for expensive operations:
- `UV_PYTHON_INSTALL_DIR` — avoids re-downloading Python interpreters
- `UV_CACHE_DIR` — avoids re-downloading packages on rebuild
- `UV_PROJECT_ENVIRONMENT` — preserves shared project virtual environments

---

## Environment Variables Set

All variables are written to `/etc/profile.d/uv.sh`:

```
UV_PYTHON_INSTALL_DIR=/opt/uv/python
UV_CACHE_DIR=/opt/uv/cache
UV_PROJECT_ENVIRONMENT=/opt/uv/venv
UV_TOOL_DIR=/usr/local/share/uv/tools
UV_TOOL_BIN_DIR=/usr/local/share/uv/bin
PATH=/usr/local/share/uv/bin:$PATH   (appended)
```

---

## Implementation Notes / Gotchas

- **`su --login` resets the environment.** When `remote_user_do` calls
  `su --login`, a new login shell is started and inherits only the login
  environment.  Pass UV env vars explicitly via `env` when running
  `uv tool install` as the remote user.

- **Volume hides image-layer content at runtime.** Do not install tools or
  write required files to `/opt/uv/` in `install.sh`.  Only create the
  directory skeleton for the volume mount to work cleanly.

- **uv installer accepts `UV_UNMANAGED_INSTALL`.** Setting this env var
  installs the binary to the given path and disables uv's self-update
  mechanism — appropriate for managed environments like devcontainers.
  Pass `UV_VERSION` alongside for version pinning.

- **Alpine uses musl libc.** uv distributes musl builds; the official
  installer handles arch/libc detection automatically.

- **Arch Linux: `curl` may already be present** but `ca-certificates` might
  be named differently (`ca-certificates-utils`).  Use `install_packages`
  with the distro guard.

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
6. `/usr/local/share/uv/bin` is on `PATH`
7. All default tools (ruff, pytest, ty, black, pyright, pre-commit, rust-just)
   are installed and executable
8. `toolsToInstall=""` skips tool installation (no binaries present)
9. Re-install is idempotent (second install exits 0, `uv --version` works)
10. Specific `version` option installs that exact version

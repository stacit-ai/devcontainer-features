# Feature Spec: micromamba

## Goals

Install [micromamba](https://github.com/mamba-org/micromamba-releases), a
statically linked single-file package manager for conda packages. The feature:

1. Places `micromamba` on the system `PATH`.
2. Uses the remote user's default micromamba root prefix.
3. Optionally initializes micromamba for the remote user's shell.
4. Supports installing the latest or a specific micromamba release build.

---

## Supported Platforms

| Image family | Status |
|---|---|
| Debian / Ubuntu (apt) | supported |
| RHEL / AlmaLinux (dnf/yum) | supported |
| Arch Linux (pacman) | supported |
| openSUSE (zypper) | supported |
| Alpine (apk) | not supported |
| `mcr.microsoft.com/devcontainers/base:*` Debian / Ubuntu | supported |

Alpine is excluded because the official micromamba manual installation docs
require a glibc-based system and state that Alpine does not work natively.

---

## Options

| Option | Type | Default | Description |
|---|---|---|---|
| `version` | string | `"latest"` | micromamba release/build tag to install. Use `"latest"` for the current release. |
| `initShell` | string | `"auto"` | Shell to initialize with `micromamba shell init`. `"auto"` detects the remote user's login shell; `"none"` skips initialization. |

---

## Directory Layout

```
/usr/local/bin/micromamba     <- wrapper that defaults MAMBA_ROOT_PREFIX
/usr/local/lib/micromamba/    <- micromamba executable
~/micromamba/                 <- remote user's default MAMBA_ROOT_PREFIX
```

---

## Implementation Notes / Gotchas

- **Use official release artifacts.** The feature downloads
  `https://github.com/mamba-org/micromamba-releases/releases/<version>/download/micromamba-<platform>`
  non-interactively, matching the official install script's release URL shape.
- **Platform names are API-specific.** Linux `x86_64`, `aarch64`, and
  `ppc64le` map to `linux-64`, `linux-aarch64`, and `linux-ppc64le`.
- **Root prefix belongs to the remote user.** The feature pre-creates
  `${_REMOTE_USER_HOME}/micromamba` and runs shell initialization as the remote
  user.
- **The PATH command is a wrapper.** `/usr/local/bin/micromamba` sets
  `MAMBA_ROOT_PREFIX=${HOME}/micromamba` only when the caller has not already
  set `MAMBA_ROOT_PREFIX`, then delegates to the real executable.
- **`initShell=none` only skips initialization.** `/usr/local/bin/micromamba`
  remains available.
- **`initShell=auto` depends on common-utils ordering.** The feature declares
  `installsAfter` for `ghcr.io/devcontainers/features/common-utils` so default
  shell detection happens after common-utils has changed the login shell.
- **System dependencies are delegated to `package`.** The feature depends on
  `ghcr.io/stacit-ai/devcontainer-features/package:1` to install `curl`,
  `ca-certificates`, and `sudo`.

---

## External References

- micromamba releases README: <https://github.com/mamba-org/micromamba-releases>
- micromamba installation docs: <https://mamba.readthedocs.io/en/latest/installation/micromamba-installation.html>

---

## TDD Behavior Backlog

1. `micromamba` is on `PATH` after install.
2. `/usr/local/bin/micromamba` exists and is executable.
3. The root prefix is the remote user's `~/micromamba`.
4. Default `initShell=auto` initializes the detected shell.
5. Re-install is idempotent.
6. `initShell=none` skips shell initialization while keeping `micromamba` available.
7. `initShell=auto` detects a zsh login shell after common-utils.
8. Specific `version` option installs from that micromamba release build.

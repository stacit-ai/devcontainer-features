# Feature Spec: miniforge

## Goals

Install [Miniforge](https://github.com/conda-forge/miniforge), a minimal
conda-forge distribution that includes `conda` and `mamba`. The feature:

1. Installs Miniforge for the devcontainer remote user.
2. Makes `conda` and `mamba` available on the system `PATH`.
3. Optionally initializes conda for the remote user's shell.
4. Supports installing the latest or a specific Miniforge GitHub release.

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

Alpine is excluded because the Miniforge Linux installers require glibc.

---

## Options

| Option | Type | Default | Description |
|---|---|---|---|
| `version` | string | `"latest"` | Miniforge GitHub release tag to install. Use `"latest"` for the current release. |
| `initShell` | string | `"auto"` | Shell to initialize with `conda init`. `"auto"` detects the remote user's login shell; `"none"` skips initialization. |

---

## Directory Layout

```
~/.miniforge3/            <- Miniforge install prefix owned by remote user
/usr/local/bin/conda      <- symlink to ~/.miniforge3/bin/conda
/usr/local/bin/mamba      <- symlink to ~/.miniforge3/bin/mamba
```

---

## Implementation Notes / Gotchas

- **Install for the remote user.** The install prefix is
  `${_REMOTE_USER_HOME}/.miniforge3` so the remote user can manage conda
  environments without root ownership conflicts.
- **Installer assets are platform-specific.** `latest` downloads
  `Miniforge3-Linux-$(uname -m).sh` from the latest release. Pinned versions
  download `Miniforge3-<version>-Linux-$(uname -m).sh` from the matching tag.
- **Repeated installs use update mode.** If the prefix already exists, the
  installer runs with `-u` to keep duplicate feature installs idempotent.
- **`initShell=none` only skips initialization.** `conda` and `mamba` remain
  available through `/usr/local/bin` symlinks.
- **`initShell=auto` depends on common-utils ordering.** The feature declares
  `installsAfter` for `ghcr.io/devcontainers/features/common-utils` so default
  shell detection happens after common-utils has changed the login shell.
- **System dependencies are delegated to `package`.** The feature depends on
  `ghcr.io/stacit-ai/devcontainer-features/package:1` to install `curl`,
  `ca-certificates`, `sudo`, `bzip2`, and `gawk`. `gawk` is required for the
  Miniforge installer to run correctly on openSUSE.

---

## External References

- Miniforge README: <https://github.com/conda-forge/miniforge/blob/main/README.md>
- Miniforge releases: <https://github.com/conda-forge/miniforge/releases>

---

## TDD Behavior Backlog

1. `conda` is on `PATH` after install.
2. `mamba` is on `PATH` after install.
3. Miniforge is installed under the remote user's `~/.miniforge3`.
4. Default `initShell=auto` initializes the detected shell.
5. Re-install is idempotent.
6. `initShell=none` skips shell initialization while keeping commands available.
7. `initShell=auto` detects a zsh login shell after common-utils.
8. Specific `version` option installs from that Miniforge release tag.

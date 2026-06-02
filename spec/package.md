# Feature Spec: package

## Goals

Install system dependency packages across common Linux image families. The
feature:

1. Detects the package manager available in the current container image.
2. Combines the generic `package` option with the detected package manager's
   specific option.
3. Installs the resulting package list with the native package manager.
4. Warns and exits successfully when no packages are requested.

---

## Supported Platforms

| Image family | Package manager | Status |
|---|---|---|
| Debian / Ubuntu | apt | supported |
| Fedora / RHEL / AlmaLinux | dnf/yum | supported |
| Alpine | apk | supported |
| Arch Linux | pacman | supported |
| openSUSE | zypper | supported |

---

## Options

| Option | Type | Default | Description |
|---|---|---|---|
| `package` | string | `""` | Comma-separated list of packages to install on every supported system. |
| `apt` | string | `""` | Comma-separated list of packages to install only when `apt-get` is detected. |
| `dnf` | string | `""` | Comma-separated list of packages to install only when `dnf` or `yum` is detected. |
| `apk` | string | `""` | Comma-separated list of packages to install only when `apk` is detected. |
| `pacman` | string | `""` | Comma-separated list of packages to install only when `pacman` is detected. |
| `zypper` | string | `""` | Comma-separated list of packages to install only when `zypper` is detected. |

---

## Implementation Notes / Gotchas

- `install.sh` is POSIX `sh`, not Bash. It must avoid arrays, `local`,
  `pipefail`, and Bash-only conditionals.
- Package manager detection order is `apt-get`, `dnf`, `yum`, `apk`, `pacman`,
  then `zypper`.
- `yum` systems use the `dnf` option because there is no separate `yum` option.
- Package lists are comma-separated. Entries are trimmed, and empty entries are
  ignored.
- If no supported package manager is found, the feature exits with an error.
- If the final package list is empty, the feature prints a warning and exits
  successfully without installing anything.

---

## TDD Behavior Backlog

1. Default install with all options empty exits 0 and installs no packages.
2. Generic `package` option is installed on supported package managers.
3. `apt` option is installed when `apt-get` is detected.
4. `dnf` option is installed when `dnf` or `yum` is detected.
5. `apk` option is installed when `apk` is detected.
6. `pacman` option is installed when `pacman` is detected.
7. `zypper` option is installed when `zypper` is detected.
8. Re-install is idempotent.

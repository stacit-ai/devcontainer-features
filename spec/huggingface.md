# Feature Spec: huggingface

## Goals

Install the Hugging Face Hub CLI and provide a persistent cache root for
Hugging Face tools. The feature:

1. Installs the `hf` CLI through `uv tool install "huggingface_hub"`.
2. Sets `HF_HOME` to `/opt/huggingface`.
3. Backs `/opt/huggingface` with a named Docker volume so Hub cache files
   survive devcontainer rebuilds.

---

## Supported Platforms

| Image family | Status |
|---|---|
| Debian / Ubuntu (`apt`) | supported |
| Fedora / AlmaLinux (`dnf` / `yum`) | supported |
| Arch Linux (`pacman`) | supported |
| openSUSE Tumbleweed (`zypper`) | supported |
| Alpine (`apk`) | supported |
| `mcr.microsoft.com/devcontainers/base:*` | supported |

Compatibility has been verified against the images listed in
`test/huggingface/compatibility.txt`.

---

## Options

This feature has no user-facing options in v1.

---

## Directory Layout

```
/opt/huggingface/           <- HF_HOME and named Docker volume mount point
  hub/                      <- default HF_HUB_CACHE derived by huggingface_hub
  xet/                      <- default HF_XET_CACHE derived by huggingface_hub
  assets/                   <- default HF_ASSETS_CACHE derived by huggingface_hub
  token                     <- default HF_TOKEN_PATH derived by huggingface_hub
```

Only `HF_HOME` is set explicitly. `huggingface_hub` derives cache and token
paths from `HF_HOME`.

---

## Implementation Notes / Gotchas

- The `hf` CLI ships with `huggingface_hub`.
- The feature depends on `uv` with `toolsToInstall: "huggingface_hub"` instead
  of duplicating Python or uv installation logic.
- `install.sh` runs as root, creates `/opt/huggingface`, makes it writable for
  runtime users, and prints a concise install log.
- The feature does not read, write, or validate `HF_TOKEN`.

---

## External References

- Installation: <https://huggingface.co/docs/huggingface_hub/installation.md>
- CLI: <https://huggingface.co/docs/huggingface_hub/guides/cli>
- Environment variables: <https://huggingface.co/docs/huggingface_hub/package_reference/environment_variables.md>

---

## TDD Behavior Backlog (implementation order)

1. `hf` CLI is on `PATH` and `hf --help` exits 0
2. `HF_HOME` is set to `/opt/huggingface`
3. `huggingface_hub.constants.HF_HOME` resolves to `/opt/huggingface`
4. `huggingface_hub.constants.HF_HUB_CACHE` resolves under `/opt/huggingface`
5. `/opt/huggingface` is writable
6. Re-install is idempotent

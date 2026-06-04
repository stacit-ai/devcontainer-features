# Feature Spec: hf-mount

## Goals

Install [hf-mount](https://github.com/huggingface/hf-mount), the Hugging Face
tool for mounting Buckets and Hub repos as local filesystems. The feature:

1. Places the `hf-mount` daemon CLI on the system `PATH`.
2. Places the `hf-mount-nfs` backend binary on the system `PATH`.
3. Supports default latest-release installs and explicit release pinning.

This first version is install-only. Users start mounts at runtime because mount
sources, target paths, credentials, and container runtime permissions are
deployment-specific.

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
| macOS | not supported by this devcontainer feature |
| FUSE backend | not installed in v1 |

The supported Linux platforms match the upstream prebuilt release binaries.

---

## Options

| Option | Type | Default | Description |
|---|---|---|---|
| `version` | string | `"latest"` | hf-mount release to install. Use `"latest"` for GitHub's latest release, or a version such as `"0.6.5"` / `"v0.6.5"` for a pinned release. |

---

## Runtime Usage

Mount a public model repo:

```bash
hf-mount start repo openai/gpt-oss-20b /tmp/model
```

Mount a private or writable Bucket with a token supplied at runtime:

```bash
hf-mount start --hf-token "$HF_TOKEN" bucket myuser/my-bucket /tmp/data
```

Run the NFS backend directly in the foreground:

```bash
hf-mount-nfs repo openai/gpt-oss-20b /tmp/model
```

---

## Implementation Notes / Gotchas

- The feature installs only `hf-mount` and `hf-mount-nfs`. It does not install
  `hf-mount-fuse`, `fuse3`, or modify `/etc/fuse.conf`.
- NFS is the default backend upstream and has no system dependencies.
- The installer downloads upstream Linux release assets directly from
  `huggingface/hf-mount`.
- System dependencies are delegated to `package`: `bash`, `curl`,
  `ca-certificates`, and `sudo`.
- Alpine is intentionally excluded. With `gcompat` and `libgcc`, `hf-mount`
  starts, but `hf-mount-nfs` still fails on musl because the upstream binary
  expects the glibc resolver symbol `__res_init`.
- Pinned versions are normalized to upstream release tags. For example,
  `"0.6.5"` and `"v0.6.5"` both resolve to tag `v0.6.5`.
- The feature does not read or persist `HF_TOKEN`; users pass credentials at
  runtime through the environment or `--hf-token`.

---

## External References

- hf-mount README: <https://github.com/huggingface/hf-mount>
- Raw README: <https://raw.githubusercontent.com/huggingface/hf-mount/refs/heads/main/README.md>
- GitHub releases: <https://github.com/huggingface/hf-mount/releases>

---

## TDD Behavior Backlog (implementation order)

1. `hf-mount` binary is on `PATH` after install
2. `hf-mount-nfs` binary is on `PATH` after install
3. `hf-mount --help` executes without network or token
4. `hf-mount-nfs --help` executes without network or token
5. Specific `version` option records the requested upstream release tag
6. Re-install is idempotent

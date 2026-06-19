# Feature Spec: Codex

## Goals

Install the [Codex CLI](https://developers.openai.com/codex/cli/) and share its
file-based ChatGPT login cache between dev containers on the same Docker host.
The feature:

1. Installs `codex` on the system `PATH` with OpenAI's standalone installer.
2. Persists ChatGPT credentials in a fixed `codex-auth` Docker volume.
3. Restores and synchronizes `auth.json` at container start and every 60 seconds.
4. Excludes API-key credentials from volume synchronization.

## Supported Platforms

| Image family | Status |
|---|---|
| Debian / Ubuntu (apt) | supported |
| RHEL / AlmaLinux (dnf/yum) | supported |
| Arch Linux (pacman) | supported |
| Alpine (apk) | supported |
| openSUSE (zypper) | supported |

Codex's standalone installer supports Linux on x86_64 and arm64. Other
architectures are outside this feature's supported platform set.

## Options

| Option | Type | Default | Description |
|---|---|---|---|
| `version` | string | `"latest"` | Codex release accepted by the official installer's `--release` option. |

## Runtime Layout

```text
/usr/local/bin/codex                 system command
/usr/local/lib/codex-auth-sync      credential sync helper
/etc/codex/config.toml              file credential-store default
/etc/codex/remote-user              remote user selected during feature install
/var/lib/codex-auth/                fixed `codex-auth` volume
  auth.json                         shared ChatGPT credential cache
  .sync.lock                        cross-container synchronization lock
/run/codex-auth-sync.pid            per-container background-process PID
~/.codex/auth.json                  remote user's local credential cache
```

## Credential Synchronization

The `postStartCommand` invokes the sync helper as root. It performs one sync
immediately, then keeps one background process per container running a
sync-and-sleep loop with a 60-second interval.

Each sync holds `/var/lib/codex-auth/.sync.lock`. If both credential files
exist, their SHA-256 hashes are compared first. Equal hashes end the sync
immediately without parsing JSON, classifying credentials, comparing timestamps,
or changing metadata.

For different or single-sided files:

- Files must contain valid JSON.
- A non-empty `OPENAI_API_KEY` classifies a file as API-key authentication. If
  either side is API-key authentication, neither file is changed.
- A single ChatGPT credential file initializes the missing side.
- Two ChatGPT files are ordered by `last_refresh`. UTC RFC 3339 timestamps are
  normalized to nanosecond precision before lexical comparison.
- Equal, missing, or invalid timestamps do not cause an overwrite.
- Replacements use a validated temporary file and an atomic rename.

The shared file is root-owned with mode `0600`. The local file is owned by the
remote user with mode `0600`; its parent directory has mode `0700`. Logs never
include credential contents, tokens, API keys, or hashes.

API keys must be supplied separately through a secret or environment variable:

```bash
printenv OPENAI_API_KEY | codex login --with-api-key
```

## Security Boundaries

- `auth.json` contains plaintext credentials and must be treated like a password.
- Every container with the fixed `codex-auth` volume can access its ChatGPT token.
- The volume is local to one Docker daemon; it is neither encrypted nor synced
  between hosts.
- A user-level Codex setting that selects keyring storage takes precedence over
  the system file-store default and disables file synchronization in practice.
- Existing API-key credentials in the shared volume are left untouched for
  manual cleanup.

## Implementation Notes

- Installation delegates cross-distribution dependencies, including `gawk`
  for release metadata parsing and `findutils` for installer cleanup, to the
  `package` feature.
- The runtime helper is root-owned and not writable by the remote user.
- The PID file prevents duplicate loops after repeated lifecycle-hook calls.
- Runtime paths and the interval may be overridden by environment variables only
  for isolated tests; they are not public feature options.

## External References

- Codex overview: <https://developers.openai.com/codex.md>
- Codex quickstart: <https://developers.openai.com/codex/quickstart.md>
- Authentication: <https://developers.openai.com/codex/auth.md>
- Dev Container Feature lifecycle hooks: <https://containers.dev/implementors/features/#lifecycle-hooks>

## TDD Behavior Backlog

1. `codex` is available on `PATH`
2. A requested Codex release is installed
3. The fixed volume and `postStartCommand` are declared
4. A single ChatGPT credential file initializes the missing side
5. Equal hashes return without changing either file's metadata
6. Different ChatGPT credentials synchronize by `last_refresh`
7. Equal or unusable timestamps do not overwrite either file
8. API-key credentials on either side disable synchronization
9. Writes are atomic and receive the required ownership and permissions
10. Concurrent sync calls serialize on the shared lock
11. The background process starts once and repeats at the configured interval
12. A second feature installation is idempotent

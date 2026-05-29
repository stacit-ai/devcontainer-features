# Quality Requirements

## Commit Message Format

Conventional Commits 1.0.0.  Scope = feature name when the change is scoped to
one feature; omit scope for cross-cutting changes.

### Scope Rules

| Changed paths | Scope |
|---|---|
| `src/<name>/`, `spec/<name>.md`, `test/<name>/` | `<name>` |
| `.github/workflows/`, `AGENTS.md`, `.agents/`, `README.md` | *(none)* |
| Multiple features in one commit | *(none)* — split commits instead |

### Type Guide

| Type | When |
|---|---|
| `feat` | new feature or new option |
| `fix` | bug fix |
| `test` | adding or fixing tests only |
| `docs` | spec, README, knowledge-base changes only |
| `ci` | workflow files under `.github/workflows/` |
| `chore` | dependency bumps, tooling, harness maintenance |
| `refactor` | code restructure with no behavior change |

### Examples

```
feat(uv): add fish shell completion support
fix(uv): correct /opt/uv ownership for non-root user
test(uv): add scenario for empty toolsToInstall
docs(uv): document Alpine compatibility caveat
ci: add AlmaLinux to test-multios matrix
chore: update dorny/paths-filter to v3
```

## Git Author Email

This is a public repository.  **Never commit with a personal email address.**

Required format: an anonymous noreply address.

| Provider | Format |
|---|---|
| GitHub | `<username>@users.noreply.github.com` |
| GitLab | `<username>@users.noreply.gitlab.com` |
| GitHub Actions bot | `github-actions[bot]@users.noreply.github.com` |

Configure locally:

```bash
git config user.email "<username>@users.noreply.github.com"
# or globally:
git config --global user.email "<username>@users.noreply.github.com"
```

Verify: `git config user.email`

## Shell Structure

Bash code must be organized around named functions when it does more than a
couple of direct commands. This applies to `install.sh`, helper scripts, and
GitHub Actions `run: |` blocks.

- Keep top-level Bash limited to constants, function definitions, and a final
  `main "$@"` call for non-trivial scripts.
- Use verb-phrase function names to document intent, such as
  `write_detected_features_summary`, `install_deps`, or `create_uv_cache_dirs`.
- Prefer self-documenting function names over comment banners that separate
  long blocks of commands.
- Extract a function once a block has conditionals, loops, `case` statements,
  multi-stage output generation, or explicit error handling.
- Devcontainer feature tests are the exception: `test/<name>/*.sh` must use
  `source dev-container-features-test-lib`, express assertions with `check`,
  and end with `reportResults`. Do not reimplement pass/fail reporting,
  assertion helpers, or a custom test runner in feature tests.
- Short one- or two-command `run:` blocks may remain inline. Longer workflow
  shell blocks must define functions and call an entrypoint instead of listing
  a loose sequence of commands.

## Pre-Commit Checklist

Run these four checks **before every commit**, in order:

### 1. Email check

```bash
git config user.email
```

Must match `*@users.noreply.github.com` or `*@users.noreply.gitlab.com`.
**Stop and reconfigure if it doesn't.**

### 2. Secrets / PII scan

Review `git diff --staged` for:
- API keys, tokens, passwords, private certificates
- Real names or personal email addresses embedded in code or comments
- Internal hostnames, IP addresses, or credentials

When in doubt, use the `sensitivity-check` skill.

### 3. Shell script lint (if `install.sh` is staged)

```bash
shellcheck -S error src/<name>/install.sh
```

Fix all errors before committing.  Warnings may be suppressed with inline
`# shellcheck disable=SCxxxx` comments when there is a documented reason.

### 4. Tests (if feature source or tests are staged)

In an environment with Docker:

```bash
devcontainer features test -f <name> .
```

If Docker is unavailable, note the skip in the commit message body and ensure
CI passes before merging.

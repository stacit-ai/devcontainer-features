---
name: commit
description: >
  Commit changes in this devcontainer-features repository following project
  quality rules. Use when committing, "git commit", "stage and commit", "save
  changes", "create a commit", or "checkpoint". Enforces: anonymous git email,
  no secrets/PII in diff, shellcheck on install.sh, Conventional Commits with
  feature scope. Prefer this over the global git-commit skill for this repo.
---

# Commit

Every commit in this public repository must pass four quality gates before the
message is composed and the commit is made.

## Workflow

1. **Check git author email** — run `git config user.email`.  The value must
   match `*@users.noreply.github.com` or `*@users.noreply.gitlab.com`.  If it
   does not, stop, show the user the correct configuration command from
   `.agents/knowledge/QUALITY.md §Git Author Email`, and do not proceed until
   it is fixed.

2. **Scan staged diff for secrets / PII** — run `git diff --staged` and
   inspect the output for API keys, tokens, passwords, private certificates,
   real names, personal email addresses, internal hostnames, or credentials.
   Flag any finding to the user and do not commit until resolved.  For a
   thorough scan, invoke the `sensitivity-check` skill on the diff.

3. **Lint shell scripts** — if any `src/<name>/install.sh` is staged, run:
   ```bash
   shellcheck -S error src/<name>/install.sh
   ```
   Fix all errors before proceeding.

4. **Run tests** — if `src/<name>/` or `test/<name>/` files are staged, run:
   ```bash
   devcontainer features test -f <name> .
   ```
   If Docker is unavailable, skip this step but add a note to the commit body:
   `Tests skipped locally — CI will validate.`

5. **Compose and commit** — determine scope from the staged paths using the
   rules in `.agents/knowledge/QUALITY.md §Scope Rules`.  Write a Conventional
   Commits message (subject ≤ 72 chars).  Then commit:
   ```bash
   git commit -m "<type>[(<scope>)]: <subject>"
   ```
   Add a body (`-m "..."` twice, or use `--file`) when the commit skipped tests
   or needs extra context.

## Gotchas

- **Scope = directory name only** — use the bare feature id (e.g. `my-feature`), not
  the full path (`src/my-feature`).  Multi-feature commits get no scope.
- **`git config user.email` is local by default** — a global config or a CI
  environment may have set a different value.  Always verify in the repo.
- **shellcheck must be available** — install with `sudo apt install shellcheck`
  if missing; it is required, not optional.
- **`git diff --staged` is empty until files are staged** — run `git add`
  before starting this workflow.

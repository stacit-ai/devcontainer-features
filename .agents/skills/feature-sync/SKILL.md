---
name: feature-sync
description: >
  Keep spec, tests, and implementation in sync for an existing devcontainer
  feature. Use when modifying src/<name>/, spec/<name>.md, or test/<name>/;
  when spec and implementation diverge; when "the spec doesn't match the code",
  "add a test for X option", "update docs for feature Y", or "the test is
  failing after my change".
---

# Feature Sync

Modifications to any of the three feature parts (src, spec, test) can drift
out of sync.  This skill enforces consistency after any change.

## Workflow

1. **Identify the feature name** from the file path being modified
   (e.g. `src/<name>/install.sh` → name is `<name>`).

2. **Verify the three-part structure exists**:
   - `src/<name>/devcontainer-feature.json` and `src/<name>/install.sh`
   - `spec/<name>.md`
   - `test/<name>/test.sh`
   If any part is missing, use the `feature-add` skill to create it.

3. **Apply the change in the primary file**, then propagate to the other two:

   | Changed file | What to check / update |
   |---|---|
   | `src/<name>/install.sh` | Update `spec/<name>.md` if behavior, env vars, or platform support changed; add `check` assertions to `test/<name>/test.sh` for new behavior |
   | `src/<name>/devcontainer-feature.json` | Update `spec/<name>.md` §Options table if options added/removed/changed; update `test/<name>/test.sh` if new options affect observable behavior |
   | `src/<name>/NOTE.md` | No cross-part propagation required; NOTE.md is standalone install-time user guidance |
   | `spec/<name>.md` | Verify `install.sh` actually implements the described behavior; if not, either implement it or update the spec to reflect reality |
   | `test/<name>/test.sh` | Verify the tested commands match actual binary names / paths in `install.sh` |

4. **Confirm CI path filters** — ensure `test.yaml` and `test-multios.yaml`
   both contain a `<name>:` entry in their `dorny/paths-filter` filters.
   If either is missing, add it following the format in `.agents/knowledge/TESTING.md`.

5. **Check version bump** — if the change alters observable behavior (new
   option, changed default, removed behavior), increment `version` in
   `src/<name>/devcontainer-feature.json` following semver.

## Gotchas

- **Spec describes intent; tests verify reality** — if spec and install.sh
  disagree, prefer updating the spec to match a deliberate implementation
  decision, or updating install.sh to fulfill the spec's promise.  Never
  silently delete spec claims without understanding why they were written.
- **test.sh runs as the remote user, not root** — assertions that check
  files written by `remote_user_do()` (e.g. `~/.local/bin/<tool>`) must use
  paths relative to the test user's home, not `/root/`.
- **Both CI workflow files** (`test.yaml` and `test-multios.yaml`) each need
  the path filter entry.  Only updating one silently skips multi-OS coverage.

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
   | `src/<name>/install.sh` | Update `spec/<name>.md` if behavior, env vars, or platform support changed; add `check` assertions to `test/<name>/test.sh` for new behavior; update root `README.md` if public behavior changed |
   | `src/<name>/devcontainer-feature.json` | Update `spec/<name>.md` §Options table if options added/removed/changed; update `test/<name>/test.sh` if new options affect observable behavior; update root `README.md` if options, defaults, mounts, env vars, or usage changed |
   | `src/<name>/NOTE.md` | No cross-part propagation required; NOTE.md is standalone install-time user guidance |
   | `spec/<name>.md` | Verify `install.sh` actually implements the described behavior; if not, either implement it or update the spec to reflect reality; update root `README.md` if public feature information changed |
   | `test/<name>/test.sh` | Verify the tested commands match actual binary names / paths in `install.sh` |
   | `test/<name>/compatibility.txt` | If platforms were added or removed, update `spec/<name>.md` platform table to match |

4. **Keep root README changes minimal** — when a feature interface or
   user-visible behavior changes, update only the corresponding catalog entry,
   option list, usage example, or short note in `README.md`. Do not do broad
   README rewrites unless the user explicitly asks for one.

5. **CI path filters are auto-generated** — both `test.yaml` and
   `test-multios.yaml` scan `src/` at runtime; no manual edits to workflow
   files are needed.  The only per-feature CI artifact to maintain is
   `test/<name>/compatibility.txt` (the base image list).

6. **Check version bump** — if the change alters observable behavior (new
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
- **Feature tests use the standard test library** — write assertions as
  `check "description" <command>` and end with `reportResults`. Use
  `check "description" bash -c "..."` for compound conditions instead of
  custom `assert_*` functions or PASS/FAIL reporting.
- **CI filters are auto-generated** — `test.yaml` and `test-multios.yaml`
  scan `src/` at runtime.  Editing those workflow files is never needed when
  adding or removing a feature; only `test/<name>/compatibility.txt` needs
  to be maintained per feature.
- **Root README is a public overview** — update it for new features, feature
  interface changes, and user-visible behavior changes. Keep those edits
  narrowly scoped to the changed public information.

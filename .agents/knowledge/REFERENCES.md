# Knowledge Base — External References

## devcontainer Specification

| Resource | URL |
|---|---|
| Spec overview | <https://raw.githubusercontent.com/devcontainers/spec/refs/heads/main/docs/README.md> |
| Features spec | <https://raw.githubusercontent.com/devcontainers/spec/refs/heads/main/docs/specs/devcontainer-features.md> |
| Features distribution | <https://raw.githubusercontent.com/devcontainers/spec/refs/heads/main/docs/specs/devcontainer-features-distribution.md> |
| devcontainer.json schema | <https://raw.githubusercontent.com/devcontainers/spec/refs/heads/main/schemas/devContainer.base.schema.json> |
| devcontainer-feature.json schema | <https://raw.githubusercontent.com/devcontainers/spec/refs/heads/main/schemas/devContainerFeature.schema.json> |

## Tooling

| Resource | URL |
|---|---|
| devcontainers/action (publish to GHCR) | <https://github.com/devcontainers/action> |
| devcontainers/cli | <https://github.com/devcontainers/cli> |
| devcontainers/feature-template (quick start) | <https://github.com/devcontainers/feature-template> |
| dorny/paths-filter (CI path filtering) | <https://github.com/dorny/paths-filter> |

## Key Distribution Facts

- Features are published to GHCR as OCI artifacts:
  `ghcr.io/<owner>/<repo>/<id>:<version>`
- The `release.yaml` workflow uses `devcontainers/action` with `publish-features: "true"`.
- Version is read from `devcontainer-feature.json`; the action skips already-published versions.
- The action also generates `src/<name>/README.md` documentation (auto-PR'd back to main).

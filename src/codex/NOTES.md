# Codex credential sharing

This feature stores file-based ChatGPT credentials in the fixed Docker volume
`codex-auth`. Every container with access to that volume can read the same
credentials. Use it only with trusted containers on a trusted Docker host.

API-key credentials are deliberately excluded from volume synchronization.
Inject API keys separately through your secret-management mechanism.

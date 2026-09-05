# Security Policy

## Reporting a vulnerability

Email **security@orin-dx.com** — do not open a public issue for anything exploitable before a fix ships.

Include:

- Which crate is affected (`wisp-contracts`, `wisp-model`, `wisp-schema`, `wisp-artifacts`, `wisp-git`, `wisp-monokl`, `wisp-store`, `wisp-context`, `wisp-output`, `wisp-service`, `wisp-cli`, `wisp-mcp`)
- The concrete failure scenario — what an attacker could do, and how
- A sample artifact, workspace layout, or repro steps if you have them (redact anything sensitive first)

Expect an acknowledgment within 5 business days. We will keep you posted as a fix moves through triage and credit you in the release notes unless you would rather stay anonymous.

## Scope

Wisp reads Git-tracked JSON artifacts, inspects Git state, embeds Monokl to analyze source code, and writes canonical artifacts and a local cache. The relevant threat model:

- **Untrusted artifact JSON** — `wisp-schema` and `wisp-artifacts` parse `spec@1`/`plan@1`/… documents that may come from an untrusted branch or a malicious agent run. A crafted document that escapes the canonical path (`ArtifactId` rejects `/`, `\`, `.`, `..`), bypasses schema validation, or triggers unbounded resource use is a real finding.
- **Repository contents as instructions** — README text, comments, string literals, and copied issue text must never alter Wisp's own validation or persistence policy. Any path by which repository content changes Wisp's behavior beyond being reported as evidence is in scope.
- **Persistence and cache integrity** — canonical writes are atomic (tempfile + rename) and hashed after write; `.wisp/` is derived state. A way to make a receipt report `persisted` for bytes that were not written, or to make a stale cache entry validate as current, is in scope.
- **Git subprocess and `gix` argument handling** — `wisp-git` shells out to `git status` and walks history with `gix`. Path or ref arguments that reach the subprocess unescaped are in scope.
- **Embedded Monokl** — `wisp-monokl` runs Monokl's parsers over workspace source. Parser crashes belong to Monokl's policy; Wisp's handling of Monokl errors and partial results belongs here.
- **MCP surface** — `wisp-mcp`'s tool inputs, especially anything that names a path or an artifact id.
- **Supply chain** — the dependency tree, especially `gix`, `rusqlite` if enabled, and anything `unsafe`-adjacent.

The workspace enforces `unsafe_code = "forbid"`. A report showing that lint bypassed, or a memory-safety bug despite it, is a high-priority finding.

Out of scope: issues in Claude Code, Codex, OpenCode, or other harnesses themselves — report those to the platform.

## Supported versions

Wisp is pre-1.0 and unpublished. Security fixes land on `main` only.

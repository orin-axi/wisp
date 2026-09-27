# Wisp: Delivery Plan and Acceptance Gates

## Delivery principle

The immediate next slice is the [implementation handoff MVP](05-implementation-handoff-mvp.md), after verifying the existing artifact foundation. It precedes Milestone 2 and has no SQLite, Monokl, Michi, MCP, service, or hook dependency. Milestones below are a roadmap, not approval to implement every proposed crate.

Build the durable, portable path before the convenient path.

The first useful Wisp release is not a vector search UI or a daemon. It is a reliable way to validate, persist, inspect, and join canonical artifacts with Git and Monokl evidence. The MCP becomes valuable because it exposes that working core; it must not be the reason the core exists.

## Milestone 0 — contracts and fixtures

### Deliverables

- A pinned, immutable schema registry strategy for all initial artifact types.
- A Wisp configuration schema describing artifact locations and workspace discovery rules.
- Fixture workspaces covering valid, invalid, stale, missing, and cross-harness artifact chains.
- Public DTOs for artifact receipts, provenance, freshness, impact evidence, and briefings.
- A compatibility statement for direct-artifact fallback.

### Required decisions

- Where the canonical plugin schemas are published and how Wisp pins them.
- Whether Wisp itself is the owner of the schema registry or consumes a small, independently versioned `orin-contracts` package.
- Wisp's license and whether it permits reuse of any AGPL implementation code.
- The first artifact operation creates no commits; a future commit-capable operation requires explicit policy and authorization.

### Acceptance gates

- A fixture can validate every supported schema version without reaching into a mutable sibling checkout.
- Invalid properties, invalid IDs, and broken links fail with typed errors.
- A no-Wisp fixture can consume the same JSON artifacts directly.

## Milestone 1 — library and artifact CLI

### Deliverables

- `wisp-model`, `wisp-schema`, and `wisp-artifacts`.
- Spec-only `wisp artifact validate`, `get`, `status`, and `persist`; `list` remains later work.
- Deterministic serialization and raw-byte content hashing.
- Temp-file/rename writes and an explicit commit receipt state.
- Library artifact discovery and link checks; a public graph/status command requires its own contract.

### Acceptance gates

- A failed validation leaves no canonical target file and no cache mutation.
- A successful write is atomic under interruption simulation.
- A persistence receipt distinguishes `written_uncommitted` from `persisted`.
- Re-running the same persistence request is idempotent or reports an exact, typed conflict; it never creates ambiguous duplicate artifacts.
- CLI JSON output is snapshot-tested and stable across supported platforms.

## Pilot gate — implementation handoff

### Deliverables

- One versioned result contract and one library operation exposed by `wisp brief implement`.
- Explicit plan path and batch/task selection; validated links, identities, raw-byte SHA-256, exact criteria, source pointers, and typed gaps.
- No canonical writes, Git mutation, cache, automatic command execution, or approval inference.
- An optional Smith consumer and policy-equivalent direct-artifact fallback in Claude/AGY and Codex, implemented as a separate agent-plugins change.

### Acceptance gates

- The real binary passes happy-path and controlled failure fixtures, with one JSON document, correct exit status, and unchanged canonical inputs.
- Both harness consumers reject a known mismatch and preserve the same artifact semantics; unknown result versions use direct checks rather than guessed decoding.
- A few frozen implementation tasks have independently checked outcomes. Record mechanical preparation work and available cost evidence without claiming general performance gains.
- Only after this proof, select one measured missing capability for the next slice. Milestone 2's database and Milestone 3's provider list are not mandatory prerequisites.

## Milestone 2 — derived artifact graph and Git evidence

### Deliverables

- `wisp-git` with repository discovery, HEAD/tree/worktree fingerprints, and changed-file evidence using `gix`.
- `wisp-store` with SQLite migrations, artifact graph, link validation, freshness calculation, and FTS for selected tracked documents.
- `wisp impact` based on declared artifact files/links and Git file changes.
- Rebuild command: delete/recreate all `.wisp/` state from source of truth.

### Acceptance gates

- Deleting `.wisp/` then rebuilding produces the same derived graph from the same workspace snapshot.
- Editing a spec changes its hash and marks linked plans/briefs stale.
- Editing an unrelated file does not invalidate an unrelated briefing.
- A dirty worktree is represented distinctly from a clean commit snapshot.
- Concurrent read operations cannot observe partial SQLite state.
- For generated create, modify, delete, rename, configuration, and analyzer-version sequences, canonical derived state after each incremental update equals a clean rebuild from the same post-step canonical inputs and workspace snapshot.
- A failed refresh leaves the prior complete state readable. If publication spans transactions or caches, readers select only `last_complete_generation`.

## Milestone 3 — Monokl adapter and context compiler

### Deliverables

- `wisp-monokl` CLI adapter using Monokl's stable typed/JSON surface.
- `wisp-context` with `brief implement`, `brief review`, and `brief architecture-audit` profiles.
- Evidence provenance and Monokl precision carried into every code-backed briefing result.
- Brief cache keys and explicit truncation records.

### Acceptance gates

- A Smith-style implementation briefing retrieves the plan from disk, its linked spec, relevant criteria, declared files, relevant tests, applicable architecture constraints, and current Git delta.
- A known spec-hash mismatch prevents a successful implementation handoff; reconcile the plan before execution. Adoption requires the cross-harness policy change recorded in the MVP brief.
- Unsupported/heuristic code analysis is labeled; Wisp never reports it as exact.
- Resolved, ambiguous, unresolved, and external Monokl outcomes survive the adapter unchanged; every ambiguous candidate remains available in the typed result and no ranker turns one candidate into a resolved edge.
- Briefing output stays below a configured budget and lists what was omitted.
- Monokl unavailable/error produces a useful artifact-only briefing with a typed `code_evidence_unavailable` gap rather than a fabricated answer.

## Milestone 4 — MCP surface and Michi output integration

### Deliverables

- MCP outcomes with complete typed structured content and a basic deterministic text renderer.
- A Michi-backed TOON/KV/hints adapter using the local sibling checkout during coordinated development.
- D-029 proposes gating only Michi-dependent features on a compatible versioned release. Accept that decision before replacing D-006's existing broader publication restriction.
- `wisp-mcp` tools/resources mapping one-to-one to library operations.
- Tool schemas, mutation safeguards, and clear recovery hints.
- Harness adapter examples for Claude, Codex, and a direct CLI fallback.

### Acceptance gates

- Every MCP tool's `structuredContent` is equivalent to the CLI JSON result.
- Text/TOON output, when TOON is enabled, is derived from the same typed result and never reparsed.
- Read-only MCP calls cause no canonical file, Git, or cache-write side effect beyond explicitly documented harmless read/access metadata.
- A harness without MCP can run the matching CLI operation and obtain the same semantic result.

## Milestone 5 — service mode and cache optimization

### Deliverables

- Optional `wisp-service`/`wispd` workspace-scoped process.
- Single-writer coordination for SQLite derived state.
- Filesystem/Git invalidation watcher.
- Warm Monokl session integration once Monokl offers a stable library/session API.
- Service health, version/config compatibility, and graceful cold fallback.

### Acceptance gates

- Two CLI/MCP clients can query the same workspace concurrently without cache corruption or cross-request evidence leakage.
- A source/artifact change invalidates precisely the dependent records.
- Stopping the service leaves the CLI able to perform a correct cold query.
- Service response correctness equals one-shot library response correctness for the same fixed workspace snapshot.
- Incremental service state equals a cold one-shot rebuild after repeated create, modify, delete, rename, configuration, and analyzer-version changes, including a failed-refresh case that keeps the previous complete publication visible.

## Milestone 6 — optional semantic retrieval

### Deliverables

- An opt-in `wisp-semantic` feature, provider/configuration boundary, and content-hash/versioned embedding records.
- Candidate retrieval for prose documents and decisions.
- Verification pass from candidate to current canonical source.

### Acceptance gates

- Wisp works fully when semantic retrieval is disabled.
- A deleted or modified source invalidates its vector chunks immediately.
- Every semantic result identifies whether it is merely a candidate or verified source-backed evidence.
- Privacy/network policy is explicit; no document is sent to a provider by default.

## Cross-harness scenarios

The fixture suite must test the actual value proposition, not only unit types.

| Scenario | Expected durable chain |
| --- | --- |
| Claude specification → Codex planning | `spec@1` written/committed, Codex reads it from its path and writes `plan@1` |
| Codex planning → Claude implementation | Claude reads the persisted plan and source spec, not an old conversation copy |
| Architecture audit before planning | model is missing → built once → later harness checks it and emits an audit |
| Spec contradiction | implementation emits contradiction → corrected spec replaces same path → amended plan replaces same path |
| No Wisp installation | Direct JSON/schema route preserves baseline behavior and reports only lost enrichment |
| Monokl unavailable | Artifact/Git briefing continues, code-evidence gap is explicit |
| Dirty worktree | Brief identifies changed files and states whether plan/spec evidence predates them |

## Evaluation plan

First prove binary/consumer integration with fixed artifacts and controlled faults. Then compare direct-artifact and Wisp-assisted runs using the same task, starting revision, harness, model, plugin/tool versions, and verification commands. Capture the baseline failure before execution and inspect the final files and terminal check results independently. Replay can test protocol handling but is not a fresh agent-outcome experiment.

Use a small repository-native runner while Prism's execution path is incomplete. Lumen analysis and a cross-harness performance matrix are later enrichment, not pilot dependencies. Correctness gates precede token/cost optimization; missing measurements remain gaps. See the MVP brief for run storage and stop/iterate criteria.

Use Prism to compare paired runs on a frozen task suite:

1. baseline: plugin receives direct artifact/filesystem context only;
2. treatment: same plugin receives the corresponding Wisp briefing.

Record task pass rate, evidence completeness, criterion coverage, incorrect stale assumptions, total tokens, cache read/write tokens where available, latency, tool calls, and cost. Use Lumen to inspect actual trajectories and detect retrieval/tool cycles. Wisp should not claim value based only on smaller payloads; a smaller briefing is an improvement only if the task result remains as correct and complete.

## Non-goals for the first release

- native named-agent packaging for every harness;
- arbitrary chat-history memory;
- mandatory daemon/service installation;
- embeddings/vector search;
- copying Monokl's AST/index into Wisp;
- remote multi-user synchronization;
- autonomous commit/push/PR creation;
- a generalized DAG agent-workflow engine.

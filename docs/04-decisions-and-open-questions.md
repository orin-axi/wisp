# Wisp: Decisions and Open Questions

This log records decisions made while designing Wisp and questions that must be resolved before a corresponding implementation milestone. It prevents a future implementation from treating an unresolved convenience choice as settled architecture.

## Decisions

### D-001: Canonical project artifacts remain Git-tracked JSON

Specifications, plans, architecture models, and related workflow artifacts are portable, reviewable files. Wisp indexes and validates them but does not move their authority into a database.

**Consequences:** agents in any harness can retain a direct JSON fallback; reviews can inspect normal diffs; cache deletion is recoverable.

### D-002: Wisp is library-first, CLI-first, MCP-later

The library contains behavior; the CLI exposes stable JSON results; MCP maps tools/resources to the same operations. No behavior is duplicated in a server adapter.

**Consequences:** CI and non-MCP harnesses benefit immediately. MCP is not a critical-path dependency for correctness.

### D-003: Monokl owns code intelligence

Wisp uses Monokl for code search, AST facts, symbols, references, definitions, and precision. Wisp owns artifact/Git/code relevance joins.

**Consequences:** no second parser or persistent code index in Wisp; code facts retain the analyzer's precision/provenance.

### D-004: SQLite stores rebuildable relationships, not canonical content

SQLite is useful for artifact links, source snapshots, impact edges, FTS, and brief cache lookup. It may cache pointers and hashes; it does not become the only copy of a spec/plan/decision.

**Consequences:** source-of-truth reads remain possible without SQLite and database migrations can be rebuilt safely.

### D-005: Vector retrieval is optional and non-authoritative

Semantic retrieval can improve prose discovery later. It returns candidates, which must be verified against current source files before inclusion as facts.

**Consequences:** no embedding provider, privacy policy, or vector dependency blocks initial implementation.

### D-006: Michi is an output adapter

Wisp uses Michi to render compact TOON/KV/hints and MCP responses through a local path dependency during coordinated development. Wisp is not published until Michi has a compatible, versioned release. Wisp domain operations work on typed values and canonical artifact persistence stays JSON.

**Consequences:** no TOON parser is needed inside Wisp's core and MCP can return both compact content and full structured content.

### D-007: Cache ownership is separate

Monokl owns its code-analysis cache. Wisp owns `.wisp/` derived artifact, briefing, and relationship cache. Neither tool writes the other's cache.

**Consequences:** independent invalidation contracts, simpler debugging, no coupling to private cache schemas.

### D-008: Context must be bounded and explainable

Every briefing includes the reasons/source pointers for selected evidence and a truncation record when its budget excludes material.

**Consequences:** Wisp is a context compiler, not an unbounded document dump.

### D-024: Resolution outcomes survive every Wisp boundary

Precision alone cannot distinguish a resolved target from an ambiguous candidate set or an external symbol. Wisp preserves Monokl's typed resolution outcome, candidates, diagnostics, resolver identity/version, and scope completeness in code-backed results.

**Consequences:** ranking may choose what to display, but it cannot manufacture a resolved relationship; compact telemetry may summarize candidate count while the typed result retains identities.

### D-025: Complete publication is a property, not a mandatory generation store

One SQLite transaction is the default publication boundary. A monotonic `last_complete_generation` is introduced only when a refresh must span multiple transactions or coordinate multiple caches.

**Consequences:** readers observe old-complete or new-complete state without importing Atlas's persistent-index architecture into every milestone.

### D-026: Incremental state must equal a clean rebuild

Watcher events and incremental paths are performance hints, not an alternate truth model. Generated create, modify, delete, rename, configuration, and analyzer-version sequences are checked against a cold rebuild after every step.

**Consequences:** an optimization that learns less than the rebuild is a correctness defect even if its changed-file path passes unit tests.

### D-027: Git-history signals are advisory

Co-change frequency and ownership concentration may later influence briefing ranking or risk warnings, but they are not code dependencies, impact proof, or structural-centrality edges.

**Consequences:** every history signal carries its kind, basis/window, and provenance; Prism must ablate each signal before it can become a default ranking feature.

### D-028: Prove an artifact-only implementation handoff first

**Status:** Proposed; implementation requires a reviewed specification and plan.

**Governs:** The delivery sequence and proposed `wisp brief implement` operation.

**Context:** The working tree has artifact validation and discovery, while code-provider, store, and evaluation integrations remain incomplete. Requiring all of them before a consumer handoff would prevent a small useful experiment.

**Decision:** Start with an explicit, read-only plan/spec preflight and exact batch/task context. Keep approval and execution in the caller; keep the first operation cache-free.

**Options considered:** Defer SQLite, warm sessions, MCP, compact rendering, and automatic orchestration because their correctness and operational costs are unnecessary to prove this boundary. Retain direct-artifact consumption because Wisp must remain optional.

**Consequences:** One wire contract and representative consumer fixtures precede broader integrations. Existing code-evidence and incremental-parity requirements still govern later features.

**Guardrail:** Do not add a database, provider, daemon, hook, or approval inference to the pilot without revisiting its specification and this decision.

### D-029: Gate optional rendering at its dependency boundary

**Status:** Proposed; would partially supersede D-006's publication restriction if accepted.

**Governs:** Release requirements for Michi-dependent features; D-006's presentation boundary remains unchanged.

**Context:** The pilot exchanges JSON and does not depend on Michi. D-006 currently prevents any Wisp publication until Michi has a compatible release.

**Decision:** Propose allowing an independently verified JSON-only release without Michi; require a compatible versioned dependency before releasing features that use Michi.

**Options considered:** Reject making all releases wait for an unused renderer because it couples unrelated delivery paths. Reject publishing a required local-path dependency because consumers cannot reproduce that build.

**Consequences:** This proposal does not authorize release. On acceptance, mark D-006 partially superseded and retain its original reasoning; update release gates consistently.

**Guardrail:** Do not publish a Michi-dependent feature without a reproducible compatible dependency.

## Open questions

### Q-001: Schema registry ownership

**Current baseline:** Five schema files are vendored with revision/checksum provenance. Keep agent-plugins as the source owner for the pilot and pin a result contract before consumer implementation. A separate contracts package is not a pilot prerequisite; long-term distribution remains open.

The existing plugin schemas live in the plugin repository. Wisp needs a pinned, releaseable registry with immutable versions. Options:

1. create a small standalone `orin-contracts` Rust/package/schema repository;
2. publish the schema directory as a versioned package from agent-plugins;
3. vendor schemas into Wisp initially with explicit source revision/checksums.

**Decision criterion:** a consumer must be able to validate `spec@1` without a mutable sibling checkout, while preserving an authoritative schema history.

### Q-002: Artifact commit policy

**Current baseline:** WISP-001 and the proposed read-only pilot create no commits. The caller owns authorization and durable workflow policy. The commit-capable options below are future decisions, not existing behavior.

Current workflow conventions require passed specs/plans/models to be committed. Wisp must decide whether `artifact persist --commit` is always explicit, whether a policy file can require it for certain types, and how a harness with no Git write approval performs graceful degradation.

**Minimum invariant:** a receipt must never call an uncommitted file durable cross-session persistence.

### Q-003: Wisp license and Callisto reuse

Callisto has differently licensed layers. Before reusing code rather than a design pattern/API, decide Wisp's license and verify compatibility. Direct `gix` usage remains an alternative.

### Q-004: Monokl public API readiness

Monokl's design includes a library-oriented architecture but its public stable Rust API and daemon/session form need confirmation. Wisp should begin with a versioned CLI JSON adapter and replace it only after a compatibility-tested library interface exists.

### Q-005: Workspace configuration

Decide the configuration filename, discovery hierarchy, and whether a default layout is inferred only when all required paths exist. Configuration must be easy to audit and must contribute to cache invalidation.

### Q-006: Artifact identity and path mapping

`spec@1` has an `id`; `plan@1` is keyed by `linked_spec`; the architecture model is a singleton. Define one public path-resolution table, enforce it at write time, and make collision/amendment behavior explicit.

### Q-007: SQLite topology and service lifecycle

Choose whether one-shot CLI use opens SQLite directly with an inter-process writer lock, or whether write-heavy use requires a local service. The answer must include lock timeouts, recovery after crash, migrations, and behavior on network filesystems.

### Q-008: Privacy and semantic retrieval

If semantic retrieval later calls a remote embedding provider, define opt-in, data boundaries, cache encryption expectations, provider/model versioning, and offline behavior before implementing it.

### Q-009: MCP SDK and compatibility surface

Select an MCP Rust transport implementation only after the library/CLI DTOs are stable. The selection must support structured content, resource URIs, tool schemas, cancellation, error mapping, and local stdio operation.

### Q-010: Freshness semantics for dirty worktrees

Define whether a briefing can be `current` when artifacts are committed but code has uncommitted changes, and distinguish: clean matching commit, clean different commit, dirty but unaffected, and dirty potentially affected.

### Q-011: History-signal value

Determine whether co-change frequency, recent ownership, or ownership concentration improves briefing relevance or review-risk detection after controlling for explicit artifact links, current Git delta, and Monokl structure.

**Decision criterion:** Prism must show lift on frozen fixtures and report false-positive cost. A signal that only correlates with repository size or commit frequency stays disabled.

## Early architectural spikes

Before committing to a large implementation, time-box these proof exercises:

1. **Artifact writer spike:** validate/persist one `spec@1`, compute raw-byte hash, commit it, and prove crash-safe/failed-commit receipts.
2. **Monokl adapter spike:** request definitions/references for a fixture and preserve precision/provenance in a Wisp typed result.
3. **Rebuild spike:** generate an artifact graph in SQLite, delete `.wisp/`, rebuild it, and compare deterministic output.
4. **Briefing spike:** compile one Smith-style briefing with an explicit token budget and prove stale-plan detection.
5. **MCP parity spike:** expose one read-only briefing operation and prove its structured content matches CLI JSON exactly.

None of these spikes authorizes broad product behavior by itself. Each exists to retire one high-risk assumption before the related milestone is built.

# Wisp: Decisions and Open Questions

This log records decisions made while designing Wisp and questions that must be
resolved before a corresponding implementation milestone. It prevents a future
implementation from treating an unresolved convenience choice as settled
architecture.

## Decisions

### D-001: Canonical project artifacts remain Git-tracked JSON

Specifications, plans, architecture models, and related workflow artifacts are
portable, reviewable files. Wisp indexes and validates them but does not move
their authority into a database.

**Consequences:** agents in any harness can retain a direct JSON fallback;
reviews can inspect normal diffs; cache deletion is recoverable.

### D-002: Wisp is library-first, CLI-first, MCP-later

The library contains behavior; the CLI exposes stable JSON results; MCP maps
tools/resources to the same operations. No behavior is duplicated in a server
adapter.

**Consequences:** CI and non-MCP harnesses benefit immediately. MCP is not a
critical-path dependency for correctness.

### D-003: Monokl owns code intelligence

Wisp uses Monokl for code search, AST facts, symbols, references, definitions,
and precision. Wisp owns artifact/Git/code relevance joins.

**Consequences:** no second parser or persistent code index in Wisp; code facts
retain the analyzer's precision/provenance.

### D-004: SQLite stores rebuildable relationships, not canonical content

SQLite is useful for artifact links, source snapshots, impact edges, FTS, and
brief cache lookup. It may cache pointers and hashes; it does not become the
only copy of a spec/plan/decision.

**Consequences:** source-of-truth reads remain possible without SQLite and
database migrations can be rebuilt safely.

### D-005: Vector retrieval is optional and non-authoritative

Semantic retrieval can improve prose discovery later. It returns candidates,
which must be verified against current source files before inclusion as facts.

**Consequences:** no embedding provider, privacy policy, or vector dependency
blocks initial implementation.

### D-006: Michi is an output adapter

Wisp uses Michi to render compact TOON/KV/hints and MCP responses through a
local path dependency during coordinated development. Wisp is not published
until Michi has a compatible, versioned release. Wisp domain operations work
on typed values and canonical artifact persistence stays JSON.

**Consequences:** no TOON parser is needed inside Wisp's core and MCP can return
both compact content and full structured content.

### D-007: Cache ownership is separate

Monokl owns its code-analysis cache. Wisp owns `.wisp/` derived artifact,
briefing, and relationship cache. Neither tool writes the other's cache.

**Consequences:** independent invalidation contracts, simpler debugging, no
coupling to private cache schemas.

### D-008: Context must be bounded and explainable

Every briefing includes the reasons/source pointers for selected evidence and a
truncation record when its budget excludes material.

**Consequences:** Wisp is a context compiler, not an unbounded document dump.

## Open questions

### Q-001: Schema registry ownership

The existing plugin schemas live in the plugin repository. Wisp needs a pinned,
releaseable registry with immutable versions. Options:

1. create a small standalone `orin-contracts` Rust/package/schema repository;
2. publish the schema directory as a versioned package from agent-plugins;
3. vendor schemas into Wisp initially with explicit source revision/checksums.

**Decision criterion:** a consumer must be able to validate `spec@1` without a
mutable sibling checkout, while preserving an authoritative schema history.

### Q-002: Artifact commit policy

Current workflow conventions require passed specs/plans/models to be committed.
Wisp must decide whether `artifact persist --commit` is always explicit, whether
a policy file can require it for certain types, and how a harness with no Git
write approval performs graceful degradation.

**Minimum invariant:** a receipt must never call an uncommitted file durable
cross-session persistence.

### Q-003: Wisp license and Callisto reuse

Callisto has differently licensed layers. Before reusing code rather than a
design pattern/API, decide Wisp's license and verify compatibility. Direct
`gix` usage remains an alternative.

### Q-004: Monokl public API readiness

Monokl's design includes a library-oriented architecture but its public stable
Rust API and daemon/session form need confirmation. Wisp should begin with a
versioned CLI JSON adapter and replace it only after a compatibility-tested
library interface exists.

### Q-005: Workspace configuration

Decide the configuration filename, discovery hierarchy, and whether a default
layout is inferred only when all required paths exist. Configuration must be
easy to audit and must contribute to cache invalidation.

### Q-006: Artifact identity and path mapping

`spec@1` has an `id`; `plan@1` is keyed by `linked_spec`; the architecture model
is a singleton. Define one public path-resolution table, enforce it at write
time, and make collision/amendment behavior explicit.

### Q-007: SQLite topology and service lifecycle

Choose whether one-shot CLI use opens SQLite directly with an inter-process
writer lock, or whether write-heavy use requires a local service. The answer
must include lock timeouts, recovery after crash, migrations, and behavior on
network filesystems.

### Q-008: Privacy and semantic retrieval

If semantic retrieval later calls a remote embedding provider, define opt-in,
data boundaries, cache encryption expectations, provider/model versioning, and
offline behavior before implementing it.

### Q-009: MCP SDK and compatibility surface

Select an MCP Rust transport implementation only after the library/CLI DTOs are
stable. The selection must support structured content, resource URIs, tool
schemas, cancellation, error mapping, and local stdio operation.

### Q-010: Freshness semantics for dirty worktrees

Define whether a briefing can be `current` when artifacts are committed but
code has uncommitted changes, and distinguish: clean matching commit, clean
different commit, dirty but unaffected, and dirty potentially affected.

## Early architectural spikes

Before committing to a large implementation, time-box these proof exercises:

1. **Artifact writer spike:** validate/persist one `spec@1`, compute raw-byte
   hash, commit it, and prove crash-safe/failed-commit receipts.
2. **Monokl adapter spike:** request definitions/references for a fixture and
   preserve precision/provenance in a Wisp typed result.
3. **Rebuild spike:** generate an artifact graph in SQLite, delete `.wisp/`,
   rebuild it, and compare deterministic output.
4. **Briefing spike:** compile one Smith-style briefing with an explicit token
   budget and prove stale-plan detection.
5. **MCP parity spike:** expose one read-only briefing operation and prove its
   structured content matches CLI JSON exactly.

None of these spikes authorizes broad product behavior by itself. Each exists
to retire one high-risk assumption before the related milestone is built.

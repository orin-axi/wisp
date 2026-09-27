# Wisp: Architecture and Contracts

## System view

This is the target architecture, not an inventory of implemented capabilities. The current working tree contains model, schema, artifact, CLI, and fixture crates. The [implementation handoff MVP](05-implementation-handoff-mvp.md) adds one read-only operation to those layers before any database, Monokl adapter, or service is required.

```text
                         canonical inputs
 ┌───────────────────────────────────────────────────────────────────┐
 │ Git worktree/history   docs/*.json   ADRs/docs   Monokl evidence   │
 └───────────────────────────────────────────────────────────────────┘
              │                 │              │              │
              └─────────────────┴──────┬───────┴──────────────┘
                                       ▼
                         wisp-workspace / wisp-context
                         validate · join · rank · bound · cite
                                       │
                   ┌───────────────────┴───────────────────┐
                   ▼                                       ▼
            rebuildable `.wisp/`                    typed result model
            SQLite / FTS / brief cache                       │
                                                           ┌─┴──────────────┐
                                                           ▼                ▼
                                                    wisp CLI          wisp MCP
                                                    JSON/TOON          MCP result
```

The library owns the behavior. The CLI and MCP must not reimplement artifact validation, cache invalidation, Git inspection, ranking, or response shaping.

## Proposed workspace crates

| Crate | Responsibility | Dependency direction |
| --- | --- | --- |
| `wisp-model` | Public IDs, DTOs, provenance, freshness, query/result contracts | Depends on no Wisp crate |
| `wisp-schema` | Schema registry, validation, immutable schema-version resolution | `wisp-model` |
| `wisp-artifacts` | Configured paths, parsing, deterministic serialization, atomic writes, artifact-link validation | model, schema |
| `wisp-git` | Repository discovery, snapshots, diff and commit evidence | model; `gix` or compatible adapter |
| `wisp-monokl` | Typed adapter over Monokl queries and precision metadata | model; Monokl public API |
| `wisp-store` | SQLite/FTS schema, derived relationship graph, cache/invalidation metadata | model |
| `wisp-context` | Context and impact compiler; source selection, evidence reduction, freshness decisions | artifacts, git, monokl, store |
| `wisp-output` | Optional TOON/KV/hints/MCP presentation conversion using local Michi during development | model/context; Michi |
| `wisp-service` | Optional workspace-scoped long-lived process, watcher, request coordination | context/output/store |
| `wisp-cli` | Clap/CLI boundary, JSON input/output, human diagnostics | service or context/output |
| `wisp-mcp` | MCP transport, tools/resources mapped directly to service/library calls | service/output |
| `wisp-fixtures` | Fixture workspaces, contract fixtures, integration/evaluation helpers | test-only |

`wisp-model` is deliberately boring and stable. It must not depend on Tokio, MCP transport types, Monokl implementation types, SQLite, or CLI formatting.

## Recommended implementation crates

| Concern | Recommendation | Rule |
| --- | --- | --- |
| JSON | `serde`, `serde_json` | Canonical artifact schemas remain separately versioned contracts |
| Schema | `schemars` plus a JSON Schema validator | Generated Rust schema is helpful; the pinned JSON schema is authoritative |
| Errors | `thiserror` | Domain crates expose typed errors, never CLI strings |
| CLI diagnostics | `miette` | CLI boundary only; never the MCP data contract |
| Paths | `camino` | Workspace-facing paths use UTF-8 path types consistently |
| Hashes | `blake3` | Hash raw persisted bytes when a contract requires a content hash |
| Artifact handoff hashes | SHA-256 | Current receipts use SHA-256; the pilot verifies `sha256:<hex>` over exact source bytes and does not reinterpret another algorithm as SHA-256 |
| Atomic I/O | `tempfile`, `fs2` | Temp-write/rename and inter-process writer coordination |
| Git | `gix` | Use typed/in-process Git operations; preserve exact commit/tree IDs |
| Relational/FTS | `rusqlite` + SQLite FTS5 | Local-first, synchronous core, single-writer aware |
| CPU work | `rayon` | Independent CPU-bound collection/reduction only |
| Service I/O | `tokio` | Optional service/MCP/watch boundary; do not leak into models |
| Tracing | `tracing` | Structured operational events; no raw sensitive content by default |
| Filesystem watch | `notify` | Service phase only, never required for correctness |
| Snapshot/property tests | `insta`, `proptest` | Verify deterministic render and graph/invalidation invariants |

Avoid an async database abstraction until Wisp becomes a real networked service. Avoid a persistent code-search engine because Monokl already owns code search. Avoid a vector dependency in the initial build.

## Monokl integration

### Ownership boundary

Monokl owns current code facts:

- parsing and per-language analyzer capability;
- symbols, definitions, references, imports, exports, blocks, and code search;
- the content-hash-backed parse cache and code-workspace index;
- precision level and provenance of each code result.

Wisp owns cross-domain relevance:

- mapping an artifact task to relevant files/symbols/tests;
- mapping a Git delta to likely affected artifacts/invariants;
- enforcing artifact links, hashes, and freshness;
- compiling a bounded briefing with provenance.

Wisp must not copy Monokl's AST data into SQLite as a rival code index. It may store stable pointers to a Monokl result—workspace fingerprint, code content hash, symbol identity/path/range, operation, precision, resolution outcome, `Provenance.agent` (`AnalyzerId`), `Provenance.activity` (`OperationId`), and query parameters— when doing so accelerates a derived impact or briefing query.

### Integration phases

These phases enrich an already useful artifact-only handoff. Monokl's library/session API is not a prerequisite for that pilot. A code-backed phase requires a real, compatibility-tested provider interface; a document describing an API does not establish that it is implemented.

1. **CLI adapter:** invoke Monokl's stable JSON/agent output interface; cache no opaque Monokl internals in Wisp.
2. **Library adapter:** once Monokl publishes a stable public Rust API, embed it in `wisp-monokl` and exchange typed records directly.
3. **Shared workspace service:** a Wisp service can own one Monokl workspace session, keeping Monokl's in-memory parse/cache and workspace index warm.

At all phases, Monokl remains responsible for invalidating code facts on source content changes. Wisp invalidates only its derived records that depend on those facts.

### Precision is carried through

Every code-backed Wisp claim includes Monokl's capability/precision and provenance. For example, an impact edge based on an exact TypeScript resolver is materially different from one derived from a structural Rust module-path walk or a heuristic fallback. Wisp must never silently upgrade the confidence of a code relationship.

Precision and resolution are different axes. Wisp preserves Monokl's `resolved`, `ambiguous`, `unresolved`, and `external` outcomes, including every ambiguous candidate and the diagnostic/reason that explains a non-resolved result. It may rank candidates for briefing inclusion, but it must not serialize the highest-ranked candidate as if Monokl resolved it. A stored code-evidence pointer also records the producing operation, analyzer/backend version and configuration digest, input content digest, workspace fingerprint, and scope completeness.

## Artifact model and persistence

### Canonical artifacts

The current registry embeds five contracts: `requirement@1`, `research-report@1`, `spec@1`, `plan@1`, and `arch-model@1`. `schemas/PROVENANCE.md` records their upstream revision and checksums. The CLI currently writes only `spec@1`.

Additional target contracts below are future integration candidates, not claims of current support; select their actual upstream versions when adding a consumer:

- `requirement@1`
- `research-report@1`
- `spec@1`
- `plan@1`
- `arch-model@1`
- `arch-audit@1`
- `verdict@1`/`verdict@2`
- `finding-report@1`
- `changeset@2` and `release-artifact@2` where relevant

Schemas must be immutable by version. Wisp needs a pinned schema registry: a published `orin-contracts` package or a vendored, checksummed schema bundle is an explicit prerequisite. It must not silently read a mutable schema file from an unrelated checkout and call it `@1`.

### Persist operation

Current spec persistence validates, sets the canonical relative path, writes atomically, and returns a SHA-256 receipt with local Git-state classification. It does not create commits, approve artifacts, or invalidate a derived database. The broader sequence and receipt below are future design examples, not current CLI behavior. A commit-capable operation would need an explicit policy and owner authorization.

An artifact producer creates a candidate JSON document. Wisp then performs the durable mechanics:

```text
candidate JSON
  → resolve schema version
  → validate shape and artifact links
  → derive canonical destination from artifact type/ID
  → deterministic serialization
  → atomic temp write + rename
  → read raw bytes and compute content hash
  → commit if the selected workflow requires it
  → invalidate/rebuild affected Wisp derived records
  → return typed persistence receipt
```

Example receipt:

```json
{
  "status": "persisted",
  "artifact_type": "spec@1",
  "id": "SPEC-021",
  "path": "docs/specs/SPEC-021.json",
  "content_hash": "sha256:...",
  "source_revision": "git:abc123",
  "cache_invalidated": ["brief:smith:PLAN-014"]
}
```

The operation must distinguish `validated`, `written_uncommitted`, `persisted`, and `commit_failed`. It cannot claim `persisted` when Git commit failed.

### Direct-artifact fallback

Wisp is preferred but optional. Plugins retain documented direct JSON behavior: they can read a path from `spec_file_path`/`plan_file_path`, validate against a bundled schema, and record a capability/freshness gap if Wisp is not available. This preserves cross-harness interoperability and allows adoption one workspace at a time.

## Cache and store design

### Directory layout

```text
.wisp/
  config.toml                 # optional local configuration; tracked only by choice
  state.sqlite                # derived artifact/relation/FTS state
  cache/
    briefs/                   # bounded compiled context packets
    queries/                  # optional materialized query results
  locks/                      # workspace service/writer coordination
  diagnostics/                # optional sanitized operational diagnostics
```

Everything in `.wisp/` is rebuildable. Canonical artifacts remain outside it.

### SQLite tables, conceptually

| Table/view | Contents | Invalidation key |
| --- | --- | --- |
| `artifacts` | ID, type/version, canonical path, raw hash, source Git state | artifact raw bytes + config |
| `artifact_edges` | implements, links_to, governed_by, supersedes relationships | endpoint hashes |
| `source_snapshots` | resolved HEAD/tree/worktree fingerprint | Git state |
| `code_evidence_refs` | pointers to Monokl operations/results, not copied ASTs | source hash + Monokl config/version |
| `impact_edges` | derived artifact ↔ module/file/symbol relationships with evidence | inputs above |
| `briefs` | cache key, bounded payload, source pointers, truncation record | every input hash + request |
| FTS virtual tables | selected docs/artifacts and metadata | document raw hash + tokenizer config |

`code_evidence_refs` and `impact_edges` store a typed resolution outcome plus the existing `Provenance.agent` and `Provenance.activity` identities; Wisp does not invent a second “resolution origin” vocabulary. A full ambiguous candidate set remains in the typed record; summaries and telemetry may carry only status, analyzer/operation identity, and candidate count when identities are unnecessary. Historical co-change or ownership signals, if enabled later, live in a distinct evidence family and never become import/dependency edges.

### Cache keys

There is no cache in the MVP. When caching is introduced, include selection dependencies as well as returned-item digests: adding a new matching file can invalidate a query even when every previously returned file is unchanged. A workspace-wide fingerprint and selective invalidation are different policies; their trade-off must be decided and tested before claiming unrelated changes preserve cache hits.

A briefing key includes at least:

```text
workspace canonical root
+ Wisp configuration hash
+ source snapshot (HEAD/tree plus dirty-worktree fingerprint)
+ each artifact's raw-byte hash
+ Monokl version/config/query identity
+ requested stage, selected task, detail/budget options
```

When one element changes, Wisp must discard or recompute the dependent result. It must not use filesystem modification time as the authoritative identity of a canonical artifact or source file.

### Multi-process safety

SQLite allows many readers but only one writer. The preferred daemon mode is one workspace-scoped Wisp service owning write coordination and a warm Monokl session. CLI clients may attach to it or run one-shot read-only/rebuild work.

If multiple Wisp processes are allowed to write, they need an explicit inter-process lock and transaction/retry contract. A Rust `Mutex` alone is not enough. Likewise, Wisp must not directly write Monokl's cache; it asks Monokl to manage its own cache lifecycle.

A derived-state refresh has one publication boundary. When the complete replacement fits in one SQLite transaction, commit that transaction atomically and add no generation machinery. If a service refresh must span multiple transactions or coordinate SQLite with materialized caches, stage it under a monotonically increasing generation and advance `last_complete_generation` only after every required component is durable. Readers select the last complete generation and therefore observe either the prior complete state or the replacement complete state, never a mixture.

## Semantic retrieval and vectors

SQLite FTS is the first document retrieval mechanism. An optional later `wisp-semantic` capability may add embeddings for prose queries such as "where did we decide tenant isolation rules?".

Vector rows must carry:

- the source artifact/document ID and path;
- the exact source content hash and chunk bounds;
- embedding model/provider/chunking version;
- an opt-in privacy configuration.

Vector retrieval returns `candidates`. Wisp then reads the current canonical source and reports it as evidence or rejects it as stale. It must never answer "the architecture says X" solely because a vector nearest-neighbor result did.

No embeddings are needed for code retrieval: Monokl's lexical and structural signals are the primary code path.

## Context compiler

The first operation selects explicit plan tasks and exact criteria without ranking, model summarization, code facts, or persistent derived state. Its proposed wire contract, scope, and error behavior live in the [MVP brief](05-implementation-handoff-mvp.md). The richer sections below belong to later evidence providers.

### Briefing contract

`wisp-context` produces a typed `Briefing` with these conceptual sections:

| Section | Contents |
| --- | --- |
| Request | stage, goal, workspace snapshot, requested task/detail budget |
| Governing artifacts | spec/plan/requirement/decision pointers and verified hashes |
| Criteria | only acceptance criteria relevant to the requested task |
| Architecture | applicable invariants, canonical abstractions, boundary rules |
| Code evidence | Monokl symbols, definitions, captured/resolved references, tests, resolution status/candidates, precision/provenance |
| Git evidence | current changes, relevant commits/diff scope, staleness warnings |
| Risks/gaps | absent artifact, stale plan, missing model coverage, unsupported language |
| Next actions | bounded, deterministic follow-up queries—not autonomous instructions |
| Truncation | omitted categories/counts and exact retrieval expansion path |

### Briefing selection policy

1. Include required governing artifacts before optional supporting context.
2. Prefer exact, current evidence over broad or low-precision evidence.
3. Select files/symbols by explicit artifact link, task file declaration, Monokl impact evidence, and Git delta—not semantic similarity alone.
4. Include tests that prove selected criteria before unrelated test inventory.
5. Enforce a budget and expose truncation; do not silently omit evidence.
6. Never include raw chain-of-thought or private session content in a briefing.
7. Treat Git co-change and ownership as advisory ranking/risk signals only. Keep each signal's kind, basis, window, and provenance visible; never use history as proof of a code dependency.

## CLI contract

The CLI is the first integration surface. Current successes are JSON; `--format json` and `--format human` select error presentation. JSON stdout and nonzero failure exits are the machine boundary. Do not advertise future commands as installed capabilities.

Current spec-only commands:

```bash
wisp artifact validate candidate.json
wisp artifact persist candidate.json --workspace .
wisp artifact get SPEC-021 --workspace .
wisp artifact status SPEC-021 --workspace .
```

Proposed pilot command (not implemented):

```bash
wisp brief implement --workspace . --plan docs/projects/SPEC-001.json --batch B1
```

Impact queries, workflow verification commands, and text/TOON success rendering are later capabilities.

CLI JSON must be deterministic enough for snapshot/fixture tests. Human output uses `miette` diagnostics and, where appropriate, Michi rendering only after the typed operation completes.

## MCP contract

MCP follows the CLI/library contract rather than inventing another API.

Initial tools:

| MCP tool | Maps to | Mutation |
| --- | --- | --- |
| `wisp_artifact_get` | artifact read/validation | no |
| `wisp_artifact_persist` | artifact persist | yes; explicit |
| `wisp_brief` | context compiler | no |
| `wisp_impact` | impact query | no |
| `wisp_status` | workflow/freshness status | no |
| `wisp_verify` | fixture/contract verification | no |

Initial resources may expose read-only canonical artifact URIs, e.g. `wisp://workspace/<id>/artifact/SPEC-021` and a current status resource. The MCP result should contain both:

- compact agent-facing content (TOON/KV/hints through Michi where appropriate); and
- complete typed `structuredContent` matching the library result.

TOON is appropriate for uniform candidate lists such as symbols, files, criteria, findings, and affected artifacts. It is not a replacement for a canonical JSON artifact or a mutation payload.

## Michi integration

The artifact-only pilot has no Michi dependency. D-029 proposes narrowing the existing publication restriction to builds/features that actually depend on Michi; it does not authorize publishing Wisp or silently amend D-006. Until that proposal is accepted, D-006 remains the recorded release restriction.

Wisp's domain operations produce types, not strings. During coordinated local development, `wisp-output` may use Michi through an explicit local path dependency. Wisp is not published while that dependency exists; publication is gated on Michi releasing a compatible, versioned package. CLI JSON remains the portable contract even when Michi is available.

`wisp-output` uses Michi as an optional edge adapter for:

- TOON list rendering for five or more uniform rows;
- KV rendering for a single status/receipt;
- bounded/truncation-safe field presentation;
- recovery hints and structured errors;
- MCP `CallToolResult` assembly with non-duplicated structured content.

Wisp must never parse its own TOON output. The model, CLI, and MCP layers all operate from the same typed result before rendering. MCP `structuredContent` and CLI JSON remain the portable output contract.

## Other ecosystem integration

### Callisto

Callisto supplies useful design precedents for capability-gated writes, validated intent, typed provider observations, constrained transitions, and receipts derived from observed outcomes. Current Callisto Git access uses subprocesses through `CommandRunner`; do not assume an existing native `gix` adapter or standalone `callisto-vcs` crate. Wisp may evaluate its own Git backend later. Reuse code only after checking API and license fit; Callisto remains the release engine.

### Lumen

Wisp/Monokl telemetry ingestion is a target integration. The MVP records experiment evidence directly; it does not require a Lumen daemon, lifecycle hook, or new ingestion adapter. Future tool events annotate a harness session rather than masquerading as agent turns, and distinguish observed measurements from derived or modeled savings.

Lumen can measure whether Wisp improves agent behavior: context size, cache affinity, tool-loop cycles, retries, and cost. Wisp may emit sanitized tracing events that Lumen can correlate, but transcript logs must not enter Wisp's canonical project knowledge without explicit user consent and a separate provenance class.

### Prism

Prism's current test command uses a synthetic transcript, its benchmark prints fixed results, and its Red/Green grader checks only the final test run. These are not evidence of Wisp's value. Use a real repository-native fixture runner first, or repair the narrow Prism execution path; do not block the MVP on a full evaluation-platform build. Missing required checks, driver failures, and timeouts are not passes.

Prism is the quality gate for Wisp's value proposition. It should run paired experiments: direct artifact/filesystem baseline versus Wisp briefing, across the same repository tasks and multiple harnesses. Measure correctness, evidence completeness, stale-context errors, latency, tokens, and cost.

### oxc-react-docgen

This is an optional domain adapter. In React-heavy workspaces it can supply component/prop documentation facts to Wisp, with its own source hash and diagnostics. It is not a general code intelligence substitute for Monokl.

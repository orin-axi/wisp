# Ten-phase implementation sequence

## 1. Relationship to the delivery plan

[`03-delivery-plan.md`](03-delivery-plan.md) defines the milestones and their acceptance gates. This file is the finer-grained phase order *within* those milestones — the sequence work lands in, not a second set of gates. Where the two disagree, `03-delivery-plan.md` wins, and the contracts in [`02-architecture-and-contracts.md`](02-architecture-and-contracts.md) and the decisions in [`04-decisions-and-open-questions.md`](04-decisions-and-open-questions.md) win over both.

Each phase retains direct JSON portability: deleting `.wisp/` must never destroy project truth (D-004).

## 2. Phase-to-milestone map

| Phase | Milestone in docs/03 |
| --- | --- |
| 1 — Diagnostics | M0 (typed domain errors) and M1 (CLI `miette` rendering) |
| 2 — Contract registry | M0 |
| 3 — Artifact graph | M2 |
| 4 — Context assembly | M2 — the artifact-only precursor to M3's briefing compiler |
| 5 — Git evidence | M2 |
| 6 — Derived local state | M2 (brief cache); FTS deferred per D-011 |
| 7 — Query and ranking | M3 (ranking); prose FTS deferred per D-011, vectors to M6 |
| 8 — Monokl embedding | M3 |
| 9 — MCP facade | M4 |
| 10 — Evaluation and operations | M3 (Prism gate) and M5 (service concurrency and locking); fixture workspaces already land in M0 |

## 3. The phases

1. **Diagnostics** — typed errors, machine JSON by default, and `miette` human diagnostics with source spans. Domain crates expose typed errors, never CLI strings; `miette` stays at the CLI boundary and is never the MCP data contract. Complete locally.
2. **Contract registry** — vendor the portable workflow contracts from Wisp Plugins at a pinned revision (D-010): `requirement@1`, `research-report@1`, `spec@1`, `plan@1`, and `arch-model@1` first, with the remaining plugin schemas following. Expose their identity, canonical paths, and validators from `wisp-schema`. Schemas are immutable by version and vendored with provenance; Wisp never reads a mutable schema file from a sibling checkout and calls it `@1`. `wisp-contracts` carries the cross-repo vocabulary types, not the schemas.
3. **Artifact graph** — discover canonical artifacts and resolve links declared as `x-wisp-link` / `x-wisp-hash-of` / `x-wisp-artifact` schema metadata (D-016), not hardcoded in Rust — requirement → research → spec → plan. Report broken or stale links as non-fatal findings without mutating source files. The graph refolds in memory from `docs/**/*.json` on every invocation.
4. **Context assembly** — produce a deterministic JSON context package for a requested artifact, including selected linked artifacts and evidence paths. Artifact-only at this phase: no code intelligence, no budget policy. Both arrive in phase 8 and M3.
5. **Git evidence** — add bounded, read-only Git state and history evidence to context packages, with explicit freshness and unavailable-state reporting. One `git status --porcelain=v2 -z` per workspace and one path-filtered rev-walk per distinct `since` over unioned pathspecs (D-013). `ArtifactFreshness` and `EvidenceFreshness` are separate axes; `Uncommitted` and `Indeterminate` are required variants (D-014).
6. **Derived local state** — add the content-addressed brief cache under `.wisp/cache/briefs/<key>`, keyed by the `(source, Digest)` set each brief derives from, with source hashes and invalidation. No SQLite metadata store and no artifact-graph table: the graph refolds in memory (D-011), and SQLite arrives only for prose FTS, only when measured necessary. All of it remains an optimization.
7. **Query and ranking** — provide deterministic lexical retrieval over artifact prose, verify every result against current source, and return citations. Retrieval runs over the in-memory refold; an FTS index is adopted only when measurement shows prose search needs one (D-011). Vectors remain optional candidates, never truth — a `Candidate<T>` becomes `Evidence<T>` only through `confirm()` (D-005).
8. **Monokl embedding** — embed `monokl-core` as a Rust library against Monokl spec 08's `Workspace`/`Snapshot`/batch-query API (D-017). There is no CLI-adapter phase; it would be thrown away. Attach source/symbol evidence to a context package carrying Monokl's precision *and* scope, and never duplicate Monokl's AST index.
9. **MCP facade** — expose the established CLI/library operations as a thin, capability-advertising MCP server: `wisp_brief`, `wisp_artifacts`, `wisp_check` (D-019). Batching lives inside `wisp_brief`; overflow never fails closed. Direct JSON file use remains supported.
10. **Evaluation and operations** — extend the M0 fixture workspaces to the evaluation set, run Prism's two tiers, and add cache observability, concurrency/locking behavior, migration rules, and harness integration guidance.

## 4. Invariant across all phases

No phase may make an upstream repository, a live service, a vector index, or a specific agent harness required to read or write the canonical JSON artifacts.

# Wisp: Decisions and Open Questions

Decisions made while designing Wisp, and questions that must be resolved before the corresponding milestone. This log exists so a future implementation never treats an unresolved convenience choice as settled architecture. D-009 onward come from the 2026-09-03 research pass — see `docs/06-research-brief.md` for the evidence.

## Summary

| ID | Title | Rule | Status |
| --- | --- | --- | --- |
| D-001 | Canonical artifacts stay Git-tracked JSON | Authority never moves into a database | Accepted |
| D-002 | Library-first, CLI-first, MCP-later | Behavior lives in the library; no adapter duplicates it | Accepted |
| D-003 | Monokl owns code intelligence | No second parser or code index in Wisp | Accepted |
| D-004 | `.wisp/` holds only rebuildable state | Nothing under `.wisp/` is the only copy of a fact | Accepted |
| D-005 | Vector retrieval is non-authoritative | `Candidate<T>` becomes `Evidence<T>` only via `confirm()` | Accepted |
| D-006 | Michi is an output adapter | Domain operations work on typed values; persistence stays JSON; Michi depends on nothing in Wisp | Accepted — resolves Q-014 |
| D-007 | Cache ownership is separate | Neither Monokl nor Wisp writes the other's cache | Accepted |
| D-008 | Context is bounded and explainable | Every item carries source pointer and derivation route | Accepted |
| D-009 | SHA-256 for artifacts, BLAKE3 for cache keys | Prefixed OCI grammar; `sha256:` across process boundaries | Accepted |
| D-010 | Schemas vendored from Wisp Plugins; `wisp-contracts` is vocabulary only | Schemas pinned by revision and checksum in Wisp; cross-repo value types in a permissive crate | Accepted — resolves Q-001 |
| D-011 | SQLite deferred; `.wisp/` splits three ways | Graph in memory, briefs content-addressed, FTS only when measured | Accepted |
| D-012 | Evidence typing lands in Milestone 0 | `Evidence`/`Provenance`/freshness ship before any producer | Accepted |
| D-013 | Git access is batched | One `git status` per workspace; `gix` for objects and walks | Accepted |
| D-014 | Freshness is two typed axes | Commit distance filtered by declared paths, never distance-from-HEAD | Accepted — resolves Q-010 |
| D-015 | Persist receipts have seven states and a permit | `persisted`-without-commit is unrepresentable | Accepted — resolves Q-002 |
| D-016 | Links and paths are schema metadata | `x-wisp-*` annotations declare relationships; ID is the authority | Accepted — resolves Q-006 |
| D-017 | Wisp embeds Monokl as a library | Depends on Monokl spec 08; no CLI-adapter phase | Accepted — resolves Q-004 |
| D-018 | Briefings use floors, atomic groups, relevance floor | Not a single flat ranking | Accepted |
| D-019 | Three MCP tools | `wisp_brief`, `wisp_artifacts`, `wisp_check`; never fail closed | Accepted |
| D-020 | Prism paired evaluation gates Milestone 3 | Intrinsic tier plus extrinsic paired run; within-harness only | Accepted |
| D-021 | Licensing is layered | `wisp-contracts` and `wisp-model` are MIT; every other Wisp crate is FSL-1.1-MIT | Accepted — resolves Q-003 |
| D-022 | Workspace configuration is one tracked `wisp.toml` | Root file, walk up to the Git root, no cascade, fingerprint over canonicalized fields | Accepted — resolves Q-005 |
| D-023 | The caller owns the budget | Monokl core returns uncapped ranked results plus cost; `wisp-context` budgets once, across every category | Accepted |
| D-024 | Cross-repo dependencies are `git` + `rev` | Committed path dependencies are banned; a CI guard rejects path sources in the lockfile; release order is a human checklist | Accepted |
| D-025 | The integration fixture is its own repository | Pinned by submodule, because freshness is defined over commit history | Accepted |
| D-026 | An actor thread owns the `Workspace` | Fixed query pool of four, request-scoped `!Clone` leases, no `spawn_blocking` | Accepted |
| D-027 | `wisp-contracts` lives in the Wisp workspace | Published from this repo as its own crate at its own version, MIT | Accepted — resolves Q-015 |
| Q-007 | Service lifecycle and writer coordination | Lock timeouts, crash recovery, network filesystems | Open |
| Q-008 | Privacy and semantic retrieval | Opt-in, boundaries, provider versioning, offline behavior | Open |
| Q-009 | MCP SDK | Select a Rust transport once DTOs are stable | Open |
| Q-011 | Supersession model | Typed `superseded_by` field, superseded artifact retained | Open |
| Q-012 | Whether BLAKE3 earns its place | A measurement, not a literature question | Open |
| Q-013 | Derivation-route counts as a ranking signal | Cheap to carry, untested; Prism can check it | Open |

## Decisions

### D-001: Canonical project artifacts remain Git-tracked JSON

Specs, plans, architecture models, and workflow artifacts are portable, reviewable files. Wisp indexes and validates them; their authority never moves into a database.

**Consequences:** any harness keeps a direct JSON fallback; reviews inspect normal diffs; cache deletion is recoverable.

### D-002: Library-first, CLI-first, MCP-later

The library contains behavior; the CLI exposes stable JSON; MCP maps tools to the same operations. Nothing is duplicated in a server adapter.

**Consequences:** CI and non-MCP harnesses benefit immediately. MCP is not on the correctness path.

### D-003: Monokl owns code intelligence

Wisp uses Monokl for code search, AST facts, symbols, references, definitions, precision. Wisp owns artifact/Git/code relevance joins.

**Consequences:** no second parser or code index in Wisp; code facts keep the analyzer's precision and provenance.

### D-004: `.wisp/` holds rebuildable derived state, never canonical content

Nothing under `.wisp/` may be the only copy of a fact. See D-011 for what actually lives there.

### D-005: Vector retrieval is optional and non-authoritative

Semantic retrieval returns `Candidate<T>`; only `confirm()` against current canonical source produces `Evidence<T>`.

**Consequences:** no embedding provider, privacy policy, or vector dependency blocks initial implementation.

### D-006: Michi is an output adapter

Wisp uses Michi for TOON/KV/hints/MCP responses through a `git` dependency pinned by `rev` during coordinated development, with an optional developer-local `[patch]` in a gitignored `.cargo/config.toml` (D-024). Wisp is not published until Michi has a versioned release. Domain operations work on typed values; artifact persistence stays JSON.

**Michi depends on nothing in Wisp.** Q-014 resolved. Michi drops its `wisp-contracts` dependency, so its envelope slots take Michi-native rendering types rather than `wisp_contracts::BudgetReport` and `wisp_contracts::Provenance`. The conversion between the two lives in `wisp-output` — not in `wisp-contracts`, and not in Michi. The dependency then runs one way only, Michi publishes first with nothing to wait for, and D-024's release order resolves in sequence rather than in a cycle.

### D-007: Cache ownership is separate

Monokl owns its parse cache. Wisp owns `.wisp/`. Neither writes the other's; Wisp asks Monokl to `flush_cache()`.

### D-008: Context is bounded and explainable

Every briefing carries the source pointer and derivation route for each selected item, and an itemized truncation record when budget or relevance floor excludes material.

### D-009: SHA-256 for artifacts, BLAKE3 for cache keys, always prefixed

Digests use the OCI grammar `algorithm:lowercase-hex`. Anything crossing a process boundary — receipts, `spec_hash`, `code_evidence_refs` — is `sha256:`. `.wisp/` cache keys may be `blake3:`. Monokl's internal `ContentHash` adopts the same prefixed form.

**Why:** not format portability — BLAKE3 is a registered OCI algorithm. It is stdlib reach: SHA-256 is in Node `crypto`, Python `hashlib`, and `sha256sum`; BLAKE3 is in none. A plugin verifying a receipt with zero dependencies can do SHA-256. Prefixing internal hashes is what makes the cache migratable.

**Consequences:** the earlier "blake3 for canonical hashes" rule in docs/02 was the outlier and is corrected. Hash canonical serialized bytes before the temp write.

### D-010: Schemas are vendored from Wisp Plugins; `wisp-contracts` is vocabulary only

Q-001 resolved, in two parts.

- **Artifact schemas** (`spec@1`, `plan@1`, …) are authored in Wisp Plugins (`agent-plugins/shared/schemas/`), where they already follow the immutable-`@N` rule. Wisp vendors them under `schemas/` at a pinned revision with a checksum recorded in `schemas/PROVENANCE.md` — WISP-001 AC-002 is the seed. Only Wisp and Wisp Plugins consume them. Re-pin: a deliberate bump of the recorded revision and checksums; persisted artifacts are not revalidated on re-pin. Who decides a re-pin is D-027.
- **`wisp-contracts`** is a small permissively-licensed crate holding the value types that cross process boundaries between Wisp, Monokl, and Lumen: `Digest`, `CapabilityPrecision`, `Diagnostic`, `Provenance`, `SymbolId` grammar, truncation/budget report shapes. No schemas — Monokl, Michi, Lumen, and Prism never validate an artifact.

**Rule for what goes in:** if Wisp and Monokl must agree on its meaning, contracts; if Monokl computes it, `monokl-core`. Value types only, no behavior, serde-derived because they are the wire format.

### D-011: SQLite is deferred; `.wisp/` splits three ways

Artifact graph and links refold in memory from JSON on every invocation — bounded by human authorship, milliseconds, and already required by the "delete `.wisp/` and rebuild identically" gate. Brief cache is content-addressed files keyed by the `(source, Digest)` set each brief derives from. FTS over prose docs is the only trigger for SQLite, adopted when measured necessary.

**Why:** every persistent-index data point is about code files at scale (CodeGraph at 4.4k+, Glean at monorepo scale, Monokl's own unmeasured 50k estimate). Wisp's artifact graph is tens to low hundreds of documents. Glean's derived-fact rule — valid iff all inputs valid, computed structurally — is cheaper and more explainable than an opaque composite key.

### D-012: Evidence, provenance, and freshness are typed from Milestone 0

`Evidence<T>` with per-class `EvidenceSource` payloads, `Provenance` (agent, activity, inputs, fingerprint), `ArtifactFreshness`, `EvidenceFreshness`, and a single `join` combinator ship in `wisp-model` before any producer exists. Retrofitting provenance after producers exist means auditing every construction site.

### D-013: Git access is batched; `gix` for objects, `git status` for worktree

One `git status --porcelain=v2 -z` per workspace, never per artifact — measured at ~8ms spawn floor per call, ~40× saving at 50 artifacts. `gix` (or `callisto-vcs`) for refs, commits, trees, and path-filtered rev-walks. Worktree status stays a subprocess behind a trait until `gix-status` reaches a stabilization tier, switched on a benchmark.

### D-014: Freshness is two typed axes with path-filtered commit distance

Q-010 resolved. `ArtifactFreshness` (bytes changed?) and `EvidenceFreshness` (code moved?) are separate. Commit distance is filtered by declared paths, never distance-from-HEAD. `Uncommitted` and `Indeterminate` are required variants. No threshold constant; briefing profiles decide what warns. Definitions in docs/02.

### D-015: Persist receipts have seven states and a permit

Q-002 resolved. `validated`, `already_current`, `written_uncommitted`, `persisted`, `commit_declined { reason }`, `commit_failed`, `conflict { existing_id, existing_path }`. Write-without-commit is the default; commit is an explicit escalation gated by a zero-sized `ApplyPermit` minted once from the flag plus harness approval, so `persisted`-without-commit is unrepresentable. Declined commits are recorded and surfaced in briefing gaps — silence is never a clean check.

### D-016: Links, hash-of relationships, and paths are schema metadata

Q-006 resolved. `x-wisp-link`, `x-wisp-hash-of`, and root-level `x-wisp-artifact { id_field, path_template }` annotations declare cross-artifact relationships. ID is the authority and path derives from it (OpenSpec's inverse convention breaks under its own `archive` command). Enforced at write time by parsing the existing destination and returning a typed `conflict`; for `plan@1`, equal `linked_spec` is an amendment.

### D-017: Wisp embeds Monokl as a library against spec 08

Q-004 resolved. No CLI-adapter phase. Wisp depends on Monokl's `Workspace`/`Snapshot`/batch-query API (Monokl `docs/spec/08-library-session-api.md`). A Monokl MVP shipping that API for TS and Rust is a named prerequisite for Wisp Milestone 3. Wisp requests complete-scope snapshots for `dependents`/`refs` and labels partial-scope results.

### D-018: Briefings use a global cap with reserved floors, atomic evidence groups, and a relevance floor

Not a single flat ranking — starving a category is the dominant failure mode, and evidence must be jointly visible to help. One hop of import closure by default. Three detail levels per code item, degraded before dropped. Section ordering is a named policy value that Prism A/Bs.

### D-019: Three MCP tools

`wisp_brief`, `wisp_artifacts`, `wisp_check`. Batching lives inside `wisp_brief`. Never fail closed on overflow.

### D-020: Prism paired evaluation is a Milestone 3 gate, in two tiers

An intrinsic tier scores emitted briefings against ground-truth changed lines (line-level coverage, nDCG ranking, context efficiency, budget sweep) deterministically per commit. An extrinsic tier runs the same harness with and without Wisp, ≥3 seeds, cost per solved task as headline. Within-harness is the defensible claim; cross-harness wins are not.

### D-021: Licensing is layered — MIT core, FSL above

Q-003 resolved. `wisp-contracts` and `wisp-model` are `MIT`. Every other Wisp crate is `FSL-1.1-MIT`, which converts to MIT two years after each release. The permissive pair exists so a third-party harness plugin can embed the DTOs with no copyleft or competing-use obligation.

**The template is Lumen and Callisto, not Michi.** Lumen is `FSL-1.1-MIT`. Callisto holds `callisto-model` and `callisto-format` at `MIT OR Apache-2.0` under an AGPL root — the same shape as a permissive interchange layer under a restricted one. Michi and Monokl were `AGPL-3.0-or-later` until 2026-09-04 and are now `FSL-1.1-MIT`. MIT alone rather than `MIT OR Apache-2.0` for the permissive pair costs consumers Apache-2.0's explicit patent grant and buys one license file instead of two.

**The suite links cleanly.** An `FSL-1.1-MIT` crate linking an AGPL crate is a conflict for any downstream redistributor, which would have made `wisp-output` (linking Michi) and `wisp-monokl` (linking `monokl-core`) unshippable. Michi and Monokl relicensed to `FSL-1.1-MIT` on 2026-09-04, before either's first publish, so no such conflict exists. Neither designates a permissive core crate yet; that is each repository's call.

**`SymbolId` ships MIT, with the trade-off known.** A permissive core was chosen over protecting the grammar, so `SymbolId`'s grammar, parser, and `Display` are `MIT` in `wisp-contracts` and anyone may build an indexer producing comparable strings. The grammar itself is already public — Apache-2.0 in `scip.proto` — so what actually moves is Monokl's parser implementation and its Rust-impl and local-binding conventions. `docs/spec/wisp-contracts/01-contracts.md` §14 carries the full argument.

### D-022: Workspace configuration is one tracked `wisp.toml` at the workspace root

Q-005 resolved. Discovery walks up from the invocation directory and stops at the first `wisp.toml` or at the Git root, whichever comes first. No cascade and no `extends`. The default layout is inferred whenever the file is absent. The workspace fingerprint hashes the canonicalized, defaults-applied configuration, not the file bytes.

Not `.wisp/config.toml`. D-004 defines `.wisp/` as rebuildable derived state, and configuration is neither rebuildable nor derived. `.wisp/` is also the directory a workspace naturally gitignores, so config there would not survive a fresh clone and would silently change every artifact path for the next reader.

**Discovery.** `--workspace <path>` short-circuits the walk entirely. Otherwise the walk starts at cwd and stops unconditionally at the directory holding `.git`; there is no user-level or XDG fallback, because a Wisp workspace is a Git workspace by definition and a config found above the repository would describe a different one. Reaching the Git root with no file is legal and infers the default layout. Finding no `.git` either is `wisp.git.not_a_repository`, exit 3 — cwd is never silently treated as a root, because that makes one artifact id resolve to different files depending on which subdirectory the command ran in. Every path inside the file resolves relative to the file's own directory, never to cwd.

**No cascade.** Wisp's unit of work is the workspace: exactly one artifact graph, refolded in memory, per invocation. A per-directory config would describe a graph that does not exist. Ruff rejected the implicit cascade for its own reasons and offers `extend` instead; biome requires a nested config to declare itself non-root. Wisp needs neither escape hatch because it has no nesting to escape from.

**Default-layout inference is unconditional**, not gated on every directory existing. Gating means a workspace holding specs but no architecture model gets no inference at all, which is strictly worse than inferring and reporting one absence. A missing artifact directory is information, so it becomes a briefing gap and a row in `wisp status`, never a load failure. That answers Q-005's third part with no.

**Fingerprint.** A field enters iff changing it can change a compiled brief's content or an artifact's identity. In: the artifact locations, Monokl's hop and language settings, every budget cap and floor, the section-order policy, and whether FTS is enabled. Provisionally in: the `git.status` implementation choice, until D-013's benchmark proves the subprocess and `gix` dirty sets agree. Out: service lifecycle and observability settings. The fingerprint is computed over the canonicalized, defaults-applied value, so reformatting the file, reordering keys, or writing an explicit value equal to the default does not invalidate every cached brief.

The enforcement mechanism is an exhaustive destructure in the function that builds the fingerprint input, with named `_` bindings for excluded fields. A new field on the config is then a compile error until someone places it on one side of the line. A field can neither silently join the fingerprint nor silently miss it.

### D-023: The caller owns the budget

`monokl-core` returns fully ranked, deduplicated, uncapped results plus a per-op cost record. It links no tokenizer, applies no token budget, and owns no allocation policy. `wisp-context` budgets once, across every category. Core keeps only a work ceiling expressed in units it computes for free, framed as a memory guard, reporting what the ceiling cut.

**Why the caller.** Wisp's budget spans governing artifacts, criteria, invariants, code evidence, Git evidence, risks, and truncation. Monokl can see only the code slice, so a Monokl-side token budget is at best a sub-budget that Wisp must guess before knowing what the other categories cost, then re-measure. A caller-supplied measure closure is not an alternative: it has no digest, so two requests with identical ops and different measures would share an `OperationId` and provenance checking would call a stale result current. A fixed tokens-per-byte constant is not one either: code measures 3.78 bytes per token and the adversarial worst case is 1.0, so any constant is either a 3.8× overrun risk or the byte bound with extra ceremony.

**Consequences:** Wisp depends on `monokl-core` alone, never `monokl-agent`, so Monokl's CLI, wire types, allocation policy, and tokenizer choice churn without a Wisp release. Byte length is a proven upper bound on token count, which makes the byte prefilter exact rather than heuristic. `ByteUpperBound` is Wisp's default measure and needs no dependency; whether a real tokenizer earns its place is a Prism question, since it buys roughly 3.8× more evidence per budget and nobody has measured whether that improves outcomes. Definitions in docs/02 §5.4.

### D-024: Cross-repo dependencies are `git` plus `rev`, never a committed path

`monokl-core` and `michi` are declared as `git` dependencies pinned by `rev`. Local co-development uses a `[patch]` in a gitignored `.cargo/config.toml`. CI rejects a committed lockfile whose entry for either crate records no git source.

**Why, measured.** moon cannot express a sibling repository as a task input: parent traversal is rejected at parse time in both project-relative and workspace-relative form, and a task re-run after editing a file outside the workspace returns a cache hit and never invokes cargo. Since `just ci` delegates to moon, a committed path dependency means the build system reports success without building. Under `git` plus `rev` the sibling's identity is a string in `Cargo.toml` and a resolved SHA in `Cargo.lock`, both inside the boundary and both hashable — a rev bump busts the cache, measured. Separately, a path-patched dependency produces a lockfile entry with no source and no checksum, so `--locked` asserts nothing about it.

**Consequences:** publishing order is forced, because a crate uploaded to the registry may carry neither a git nor a bare path dependency. Michi goes first, then `wisp-contracts` from this repository, then Monokl, then the Wisp crates. Between steps each downstream repo converts its pinned rev to a registry requirement. `wisp-contracts` is the crate this costs most, having three consumers across three repositories; publishing it early as an explicitly unstable `0.0.x` removes that edge entirely.

**Ordering across repositories is tracked by a human, by design.** Callisto releases each repository on its own and is not asked to span them. The order above is a checklist someone follows, not a feature anyone builds. Mechanics live in `docs/07-build-and-release.md`.

### D-025: The cross-repo integration fixture is its own repository, pinned by submodule

The fixture corpus Wisp and Monokl both run against is a standalone repository with a frozen, deterministic history, consumed by each as a git submodule.

**Why forced.** D-014 defines freshness as commit distance filtered by declared paths, and D-013 batches `git status` over a real worktree. A tree checked into `wisp-fixtures/` has no independent history and cannot exercise either. A tarball loses history entirely. The corpus history must contain at least one commit touching a plan's declared paths, one touching only unrelated files, and one adding a file no artifact declares — without the second, path-filtered distance and distance-from-HEAD give the same answer and D-014 is untested.

The submodule also solves pinning: the gitlink recorded in the superproject tree is the pin, versioned atomically with the commit that needs it. This is the one place a cross-repo checkout is warranted, and the only one D-024 leaves.

**Consequences:** the corpus sits inside each workspace boundary and is therefore expressible as a moon input, unlike a sibling repo. One caveat is unmeasured: the superproject sees a submodule as a single gitlink, so a pointer bump may not mark the consuming project affected. Until that is measured, fixture-dependent tasks run unconditionally in CI rather than under `--affected`. Prism references the corpus by URL and tag rather than by submodule, because a frozen sample must record which revision produced it.

### D-026: An actor thread owns the `Workspace`; queries run on a fixed pool

Tokio owns the transport edge only. A tokio thread never calls into `monokl-core`, and a pool thread never calls `block_on`. An actor thread owns `Workspace` by value and publishes the current `Snapshot` beside it; readers take a `!Clone` `SnapshotLease` for the life of one request. Queries run on a fixed pool of `min(available_parallelism(), 4)`, bridged with a oneshot, never `spawn_blocking`.

**Why.** rust-analyzer, `ty`, and `ruff` all reached this shape independently, and none puts an async runtime under the analysis path. `spawn_blocking` fails on four counts from tokio's own documentation: its pool defaults to 512 threads, its queue applies no backpressure, its tasks cannot be aborted so a multi-second cold open becomes a multi-second shutdown stall, and rayon called from a non-rayon thread parks the caller for the full duration without contributing work.

**Consequences:** the pool cap is a memory bound before it is a throughput choice. Live revisions are `1 + pool_size`, so the pinned-index cost is bounded at five revisions rather than 513 — the difference between hundreds of megabytes and tens of gigabytes at 50k files. This is the mechanism behind M5's RSS gate. A `live_leases` gauge goes to Lumen so a leaked lease is observable. Definitions in docs/02 §7.4.

### D-027: `wisp-contracts` is a Wisp workspace member, published from this repository

Q-015 resolved. `crates/wisp-contracts` is a member of the Wisp workspace. It publishes to crates.io as its own crate, under its own version, licensed `MIT` (D-021). There is no separate `wisp-contracts` repository, and its spec at `docs/spec/wisp-contracts/01-contracts.md` stays here.

Wisp owns the version bump, the release cadence, and the arbitration when Monokl and Wisp want incompatible changes to the same type. The narrower re-pin question in D-010 — who bumps the vendored Wisp Plugins schema revision — answers to the same owner.

The crate belongs to no Callisto version group, so a `wisp-cli` patch never drags the contracts version and never forces a requirement bump on Monokl or Lumen. It publishes as an explicitly unstable `0.0.x` immediately, which reserves the name and lets every downstream repository depend on a registry version rather than a git URL. `docs/07-build-and-release.md` §5.1 and §7 hold the mechanics.

## Open questions

### Q-007: Service lifecycle and writer coordination

One-shot CLI takes an `fs2` lock on `.wisp/cache/`; a service owns the lock for its lifetime. Still open: lock timeouts, crash recovery, behavior on network filesystems. SQLite topology is no longer part of this question (D-011).

### Q-008: Privacy and semantic retrieval

Opt-in, data boundaries, encryption expectations, provider/model versioning, offline behavior — before any remote embedding provider is called.

### Q-009: MCP SDK

Select a Rust MCP transport after the DTOs are stable. Must support `structuredContent`, `outputSchema`, resource URIs, error mapping, stdio.

### Q-011: Supersession model

Wisp has none. The `spec_contradiction` loop overwrites in place, so a superseded spec exists only in Git history and cannot be cited. Add a typed `superseded_by` field (not a status string — MADR/log4brains show why), with the superseded artifact retained.

### Q-012: Whether BLAKE3 earns its place

If `.wisp/` cache keys are the only consumer and briefing cost is dominated by Git and Monokl, one algorithm removes a dependency and a class of "which hash is this" bugs. A measurement, not a literature question.

### Q-013: Derivation-route counts as a ranking signal

`Evidence::routes` is a hypothesis: multi-route support correlating with usefulness. Cheap to carry, untested. Prism's intrinsic tier can check it. The field is a `RouteSet` of `AffectedBy` values rather than a count (docs/02 §3.4), so the test can ask which routes correlate, not only how many.

## Early architectural spikes

| # | Spike | Retires |
| --- | --- | --- |
| 1 | **Artifact writer** | Persist one `spec@1`, hash before write, prove `already_current`, `conflict`, `commit_declined`, and crash-safe receipts |
| 2 | **Monokl session** | Open a `Workspace`, take a `Snapshot`, run a 10-op batch, `apply_change` one file, prove `is_current` flips without an index rebuild |
| 3 | **Rebuild** | Refold the artifact graph in memory, delete `.wisp/`, refold again, compare deterministic output |
| 4 | **Freshness** | One batched `git status` plus one bounded rev-walk over unioned pathspecs; prove `CleanUnaffected` vs `CleanBehind` vs `DirtyAffected` vs `Uncommitted` on a fixture |
| 5 | **Briefing** | Compile one Smith-style briefing under a global cap with floors; prove stale-plan detection and an itemized truncation record |
| 6 | **MCP parity** | `wisp_brief`'s `structuredContent` byte-equals CLI JSON |

None of these authorizes broad behavior. Each retires one high-risk assumption before its milestone.

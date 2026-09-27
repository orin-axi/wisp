# Research brief: prior art behind D-009 through D-021

Six parallel research tracks ran on 2026-09-03 against seventeen proposed changes to Wisp and Monokl. This is the condensed record — the finding, the source, what it changed. Confidence tags: `confirmed` = primary source read; `likely` = secondary or summary. Full track reports are longer than this repo wants; this file carries what a decision needs.

## 1. Session and snapshot API (Monokl spec 08)

| Finding | Source | Confidence | Changed |
| --- | --- | --- | --- |
| rust-analyzer splits `AnalysisHost` (mutable, `apply_change(&mut self)`) from `Analysis` (immutable snapshot, O(1) Arc clone). Its cancellation exists because Salsa's memo table is mutable storage shared by every snapshot, so a write waits for readers to die. Monokl's `WorkspaceIndex` is immutable after build, so `apply_change` can swap an Arc and let old snapshots go stale — no `Cancellable<T>`, no `UnwindSafe`. | rust-analyzer `crates/ide/src/lib.rs`, `docs/book/src/contributing/architecture.md` | `confirmed` | D-017 |
| `ty` (Astral) is a one-shot CLI that still builds a session database, clones it into rayon workers, and disables incremental bookkeeping (`disable_lru`, `freeze`) when nothing will change. Source of the `Lifetime::{OneShot, Session}` hint. | `astral-sh/ruff` `crates/ty/src/lib.rs`, `crates/ty_project/src/db.rs` | `confirmed` | D-017 |
| Biome takes `&self` everywhere with params structs (pre-shaped for a remote transport) and pays with `RetryingWorkspace`/`retry_on_pending_write`. In-process embedding favors rust-analyzer's shape. | `biomejs/biome` `crates/biome_service/src/workspace.rs` | `confirmed` | D-017 |
| "It's not the incrementality that makes an IDE fast. Rather, it's laziness." Source of lazy per-enricher construction. | rust-analyzer blog, three-architectures post | `confirmed` | Monokl spec 08 |
| Durability tiers recovered ~300ms per edit in rust-analyzer via a version vector, assigned by input provenance (library vs local), not measured churn. Source of `WorkspaceFingerprint { durable, volatile }` without Salsa. | rust-analyzer "Durable Incrementality" | `confirmed` | Monokl spec 08 |
| rust-analyzer's serialization invariant: "don't make it serializable; create a serializable counterpart." Monokl's `types.rs` derives `Serialize` on every core type, making one struct the API, the cache format, and the wire shape. | rust-analyzer | `confirmed` | Monokl spec 08 |
| `BufWriter`'s contract — flush-on-drop swallows errors, so call `flush` explicitly — is the precedent for `flush_cache()`. Monokl's `WorkspaceIndex::build` currently calls `persist::init`/`flush` inside construction: N ops, N flushes. | std docs; Monokl spec §19 | `confirmed` | D-007 |

## 2. Symbol identity and provenance

| Finding | Source | Confidence | Changed |
| --- | --- | --- | --- |
| SCIP identity is `<scheme> <manager> <package-name> <version> <descriptor>+`. No path (that's on `Document`), no kind (87-value `SymbolInformation.kind` is metadata; the 9-value suffix is identity), no line. Path in the ID means a rename invalidates every cached reference; kind in the ID means a `Heuristic→Structural` upgrade silently breaks every stored pointer. | `sourcegraph/scip` `scip.proto` (962 lines, read in full), `docs/DESIGN.md` | `confirmed` | D-010 |
| SCIP disclaims being "a storage format for querying" — adopt the string grammar, not the container. | `sourcegraph/scip` `DESIGN.md` | `confirmed` | D-010 |
| rust-analyzer's `local N` resets a per-document counter; inserting one binding renumbers everything below. Less stable than a line. Use scope-derived local identity, degrade to `local N` only at SCIP emission. | rust-analyzer `crates/rust-analyzer/src/cli/scip.rs` | `confirmed` | D-010 |
| No confidence or precision field exists anywhere in SCIP, LSIF, Kythe, or Glean. Per-edge precision is sound but has no interop encoding — a documented lossy boundary. | SCIP, LSIF, Kythe, Glean specs | `confirmed` | D-012 |
| Glean: identity is the key, integers are a private handle; derived facts are owned by `O1 && … && On` and visible iff all inputs are. Source of `Evidence::join`. | glean.software incrementality docs | `confirmed` | D-012 |
| Provenance semirings: `+` is alternative derivations, `·` is combined dependencies. Why-provenance (the witness set) is the right level for a briefing; how-provenance polynomials are not. Route count (`+`) is a cheap ranking signal, untested. | Green, Karvounarakis, Tannen, PODS 2007 (summary depth) | `likely` | Q-013 |
| PROV-DM's Entity/Activity/Agent split is worth borrowing as structure (who, what operation, from which inputs); its vocabulary is not. Timestamps must never be authority. | W3C PROV-DM | `confirmed` | D-012 |
| OCI digest grammar `algorithm:encoded` registers `sha256`, `sha512`, and `blake3`; SHA-256 is the only MUST. Empirically on this machine: sha256 is in Node `crypto`, Python `hashlib`, and `sha256sum`; blake3 is in none. | `opencontainers/image-spec` `descriptor.md`; local check | `confirmed` | D-009 |

## 3. Context selection and budgeting

| Finding | Source | Confidence | Changed |
| --- | --- | --- | --- |
| RepoGraph's hop ablation: baseline 27.33%, 1-hop flattened 29.67%, **2-hop flattened 26.00%** — worse than no graph. Node count 11.6 → 54.5 for one extra hop. Source of hops=1 default and fan-out caps. | arXiv 2410.14684 | `confirmed` | D-018 |
| SWE-Explore: file-level localization is solved (~0.65 file hits) but line recall sits at 0.15–0.19; "missing core evidence is the dominant failure mode"; resolve rates jump only when evidence is jointly visible. Source of reserved floors and atomic evidence groups. Also the metric framing for Prism's intrinsic tier. | arXiv 2606.07297 | `confirmed` | D-018, D-020 |
| AbsenceBench: Claude-3.7-Sonnet detects omitted content at 69.6% F1 at 5K tokens — a gap has no key to attend to. Source of the itemized truncation record. | arXiv 2506.11440 | `confirmed` | D-008 |
| JetBrains: a placeholder marker for masked observations gave +2.6% solve rate at 52% lower cost; LLM summarization matched savings but lengthened trajectories ~15%. | JetBrains research blog, Dec 2025 | `likely` | D-008 |
| "Code Isn't Memory" (SuperCoder): structural index vs same harness without, Claude Opus 4.7 held constant, 91 instances, 3 seeds — resolve 50.4% vs 41.9% (p=0.003), localization acc@5 84.5% vs 44.3%, $2.30 vs $2.84 per solved task with per-run cost null. Two tools over a three-part index; Merkle-tree diffs for incremental update. The evaluation template for Prism. | arXiv 2606.22417 | `confirmed` | D-020 |
| LocAgent: graph agent 77.74 File Acc@5 vs CodeRankEmbed 52.55 vs BM25 38.69; `traverse_hops` is agent-chosen. Nemotron-CORTEXA: fine-tuned code embedder 71.95% file recall vs BM25 40.67%. Structure > embeddings > lexical; BM25 alone is last in every paper. Source of the qualified "no code embeddings" claim. | arXiv 2503.09089; NVIDIA ADLR | `confirmed` | D-005 |
| Agentless: file → skeleton (signatures/fields/headers, ~800 lines) → edit lines; 32% SWE-bench Lite at $0.70 and 78K tokens. Source of the `Skeleton` detail level. | arXiv 2407.01489 | `confirmed` | D-018 |
| Aider repo-map: PageRank over a def/ref graph with deterministic multipliers (×10 mentioned identifiers, ×50 working-set files, ×0.1 private names and >5-file definitions, `sqrt` reference damping), then binary search over prefix length at `ok_err = 0.15`. Source of the day-one ranker and the budget-fit method. | `Aider-AI/aider` `aider/repomap.py` | `confirmed` | D-018 |
| Lost-in-the-middle is real but contested for current models; a 2026 reproduction found flat curves on some setups and that better retrieval shrinks ordering sensitivity. No source tests a headed, structured document. Ordering is a policy value Prism tests, not a hardcoded truth. | arXiv 2307.03172; arXiv 2605.27105 | `confirmed` | D-018, D-020 |
| Laws of Context Allocation: width elasticity −0.68 for evidence utilization. Source of the relevance floor — don't pad to the budget. | arXiv 2608.23252 | `confirmed` | D-018 |
| Manus: KV-cache hit rate is "the single most important metric" (10× cost difference); recitation at the recency end combats mid-context loss; keep failures in context. Stable prefix first, gaps and restatement last. | Manus engineering blog | `confirmed` | D-018 |
| No study ablates one global budget vs per-section budgets. D-018's tiered design is inferred from SWE-Explore, not measured. | — | — | D-018 |

## 4. Incremental and scoped indexing

| Finding | Source | Confidence | Changed |
| --- | --- | --- | --- |
| Glean's soundness invariant for partial visibility: every fact referenced by a visible fact is also visible; "incremental derivation on stacked databases isn't yet implemented." Meta hasn't fully solved layered incremental derivation — keep Wisp's derived layer cheap to discard. | glean.software | `confirmed` | D-011 |
| moon/Nx/Turborepo all implement git delta → owning project → closure, with closure depth as a dial (`none`/`direct`/`deep`). moon v1.29 records *why* something is affected. Source of `wisp impact --closure` and `AffectedBy`. | moonrepo, nx.dev, turborepo docs | `confirmed` | docs/02 §10 |
| Bazel's `--watchfs` repeatedly shipped bugs (ignores `.bazelignore`, 1.5-minute Windows startups) — a watcher is a latency optimization over a correct stat/hash path, never a substitute. | bazel-discuss (`confirmed`); bazel issue #13569 (`likely`) | `confirmed` / `likely` | docs/02 §2.2 |
| Kythe bundles all required inputs into each compilation unit; TypeScript project references make Find-All-References a non-feature across boundaries rather than a lossy one; `cargo check -p` checks dependencies, never dependents. Every scoped precedent breaks on the reverse-closure query. Source of `Scope` as a completeness axis and `Unsupported` for `dependents`/`refs` under `Partial`. | Kythe, TypeScript, Cargo docs | `confirmed` | D-017 |
| Monokl's `FileIdx(i as u32)` is positional over the sorted analysed set and `ImportGraph.reverse` keys on it: any create/delete renumbers everything; scoped and full opens have incomparable identities; scoped `dependents_of` under-reports silently. Prerequisite for both scoped open and `apply_change`. | Monokl spec §19 | `confirmed` | Monokl spec §19 |
| rust-analyzer's VFS: `Change::{Create(bytes, hash), Modify(bytes, hash), Delete}`, hash-gated at the source (no-op if unchanged), batched into one `apply_change`, with `has_structure_changes` distinguishing create/delete from modify. Source of Monokl's `Change` shape. | rust-analyzer `crates/vfs/src/lib.rs`, `global_state.rs` | `confirmed` | D-017 |
| Measured locally: `git status` ~8.8ms/spawn, `git log -1 -- path` ~7.3ms, one batched log 12ms. 50 artifacts × 2 calls ≈ 800ms vs ~20ms batched. | local measurement | `confirmed` | D-013 |
| `gix-status` is "Initial Development", not a stabilization candidate, no fs-monitor, no sparse-index; only `gix-lock`/`gix-tempfile` are production-grade. No `gix status` vs `git status` benchmark exists in any primary source. | gitoxide `crate-status.md` | `confirmed` | D-013 |
| CodeGraph persists to SQLite at 4.4k files with ~0.3s single-file resync; Monokl's ~50k crossover has no external corroboration and its own latency targets are unmeasured stubs. | CodeGraph README; Monokl spec line 3135/3150 | `confirmed` | D-011 |

## 5. Batch queries and tool surfaces

| Finding | Source | Confidence | Changed |
| --- | --- | --- | --- |
| LSP forbids JSON-RPC batching in normative text; MCP has no batch tool call and the 2026-07-28 RC doesn't add one; MCP pagination exists only on list operations. Batching can only live inside one tool call. | LSP base protocol 0.9 line 122; MCP 2025-11-25 tools spec | `confirmed` | D-019 |
| Anthropic's code-execution-with-MCP: "every intermediate result must pass through the model"; worked example 150,000 → 2,000 tokens. The real justification for a batch API. | Anthropic engineering | `confirmed` | D-019 |
| DataLoader: results index-parallel to keys; cache scoped to one request. Translates to "each batch runs against one immutable snapshot." | graphql/dataloader README | `confirmed` | D-019 |
| Tool-count evidence: RAG-MCP 13.62% accuracy presenting all tools vs 43.13% with retrieval; degradation past ~30. Every study operates at 30–3,251 tools; none ablates 1 vs 3. | arXiv 2505.03275, 2605.24660 | `confirmed` | D-019 |
| Sourcegraph cut its default MCP endpoint from 13 tools to 8, demoting `go_to_definition` and `find_references`, "to avoid spending context window budget"; kept all 13 at `/.api/mcp/all`. Curate the default, keep primitives reachable. | Sourcegraph changelog via mirror | `likely` | D-019 |
| Serena ships 48 tools and its docs say only a subset should be enabled; its overflow behavior returns nothing. Never fail closed. | Serena tools page (`confirmed`); glama schema mirror (`likely`) | `confirmed` / `likely` | D-019 |
| No surveyed server (Sourcegraph 13, Serena 48, GitNexus 16, Octocode 14, CodeGraph 7–42) exposes a composite "everything about symbol X" call, and none attaches a single budget report across sections. The composite briefing is the differentiation. | server tool listings | `confirmed` / `likely` | D-019 |
| Michi's `AgentResponse` holds one TOON xor one KV section (`RenderTarget { Unset, Toon, Kv }`, last setter wins); truncation is per-cell only; `PartialSuccess` has the right completed/failed/skipped shape but `Vec<String>` loses positional indexing; MCP serialization is already correct. | Michi `crates/michi-core/src/response.rs` | `confirmed` | D-006 |
| LSP 3.17's `workspaceSymbol/resolve` — cheap list now, expensive detail on demand — is the precedent for `Detail::{Lite, Full}` and degrade-before-drop. | LSP 3.17 spec | `confirmed` | D-018 |

## 6. Artifact freshness and governance

| Finding | Source | Confidence | Changed |
| --- | --- | --- | --- |
| PROJECTMEM: staleness is path-filtered commit distance ("predates 7 commits to auth.py"), flag-never-delete, retired via `--supersedes`, with the snooze itself logged. Committed: distilled outputs; gitignored: raw log and derived structure. | `riponcm/projectmem` README (801 lines); arXiv 2606.12329 | `confirmed` | D-014 |
| No spec-driven tool surveyed (Spec Kit, Kiro, Tessl) detects staleness between its own artifacts by hash. `plan@1.spec_hash` is already ahead. | Spec Kit, Kiro, Tessl docs | `confirmed` / `likely` | D-014 |
| Tessl's `check-target-ownership.sh` — a target file cannot change without its spec changing — is commit distance over declared paths by another name. | tessl.io spec-as-source | `confirmed` | D-014 |
| MADR and log4brains encode supersession inside a status string; log4brains' maintainers call the result "too restrictive." Use a typed field. | MADR, log4brains | `confirmed` / `likely` | Q-011 |
| Backstage derives all catalog relations from typed spec fields via a generic processor and forbids hand-declared edges. Precedent for `x-wisp-link`. | backstage.io descriptor format | `confirmed` | D-016 |
| `x-` keywords are collected as annotations by every published JSON Schema draft; JSON Hyper-Schema is dormant. | json-schema.org blog | `likely` | D-016 |
| Retracted: the current Callisto tree has no `callisto-vcs` crate or `commits_since_with_pathspec` API. `callisto-model` is MIT and contains `ApplyPermit`; Git access currently uses subprocesses. Do not treat the earlier VCS reuse claim as evidence. | Current Callisto `crates/*/Cargo.toml` and source, checked 2026-09-27 | `retracted` | D-013, D-015, D-021 |
| kubectl (`unchanged` vs `configured`) and Ansible (`ok` vs `changed`) always distinguish no-op from applied; cargo-release's dry-run writes files without feedback (issue #872). Source of `already_current` and the rule that write-without-commit is reported. | kubectl, Ansible, cargo-release issue #872 | `likely` | D-015 |
| OpenSpec derives identity from path, and its own `archive` command relocates artifacts and changes their identity. Keep ID as authority. | OpenSpec issue #662 | `likely` | D-016 |
| Wisp's own docs contradicted each other on hashing (blake3 at docs/02:58 vs `sha256:` in the receipt example and shipped `plan@1.spec_hash`). Corrected in D-009. | Wisp docs | `confirmed` | D-009 |

## 7. What the evidence did not settle

- **One global budget vs per-section budgets** — no ablation exists.
- **Position sensitivity for structured, headed documents** — no study; the ordering default is a prior.
- **Whether route count predicts usefulness** — hypothesis for Prism.
- **The exact definition of PROJECTMEM's commit-distance walk** (first-parent, rename-following, merge handling) — README describes it, no source read; Callisto's implementation is the one with quotable semantics.
- **Whether a Wisp `Change` should carry file bytes or let Monokl re-stat** — no precedent for the optional form.
- **Monokl's snapshot memory cost with stale snapshots held** — unmeasured, needs the benchmark.
- **1-tool vs 3-tool MCP surfaces** — no measured ablation; D-019 rests on product precedent and schema-design reasoning.

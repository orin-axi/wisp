# Implementation Handoff MVP

**Status:** Planning draft. No spec gate, plan approval, integration test, release, or performance result is implied. Start by turning this brief into reviewed portable artifacts; do not expand WISP-001's existing scope.

## Outcome

Given a persisted plan and an explicit batch or task selection, Wisp verifies the governing spec relationship and returns exact implementation context with source digests and explicit gaps. Smith retains code inspection, implementation, review, and independent verification.

The first value claim is removal of duplicated mechanical preparation and detection of known handoff inconsistencies. Reduced session cost, fewer parses, and better implementation outcomes are hypotheses to measure, not established benefits.

## Scope

- Read only the selected plan, its governing spec, and metadata necessary for this handoff.
- Validate pinned `plan@1` and `spec@1` shapes, identities, paths, references, and raw-byte SHA-256.
- Project exact selected tasks and criteria with purpose, scope, non-goals, and declared API context when present.
- Return one versioned JSON result through the library and CLI.
- Integrate an optional consumer into Smith in both harnesses as a separately reviewed agent-plugins change.

No SQLite, cache, watcher, daemon, Monokl query, Michi renderer, MCP transport, embedding, hook, arbitrary shell execution, automatic approval, commit, or release belongs in this slice. Do not create every proposed architecture crate; add the operation to the existing model/schema/artifact/CLI layers first.

## Ownership and handoffs

| Boundary | Producer | Consumer | Responsibility |
| --- | --- | --- | --- |
| Governing spec | Scribe or repository owner | Navigator and Wisp | Required behavior; caller retains review/approval evidence |
| Persisted plan | Navigator or repository owner | Wisp | Explicit tasks, criteria, paths, and the source spec hash |
| Implementation context | Wisp | Smith | Source-backed checks and exact projection, not execution approval |
| Implementation evidence | Smith and project checks | Independent reviewer/gate | Current files, commands, terminal results, and coverage gaps |
| Experiment record | Fixture runner | Maintainer; later Prism/Lumen | Actual run evidence with fixed inputs, never synthetic success |

Existing project-artifact schemas remain immutable and owned by agent-plugins. Define one new versioned result schema there before writing the plugin consumer; vendor it into Wisp with upstream revision and SHA-256 provenance. Do not introduce a contracts repository, shared package, or duplicate schema definitions for this pilot. `implementation-context@1` is a proposed contract name, not an available artifact.

Wisp does not establish that a plan was approved, that prerequisites finished, that declared files cover all affected code, or that commands are safe. The caller checks those conditions using its current workflow and authorization boundary.

## Proposed invocation

```bash
wisp brief implement --workspace . --plan docs/projects/SPEC-001.json --batch B1
```

This command is not implemented. `--plan` is a workspace-relative path, not an inferred plan ID. Require exactly one selector: `--batch` for a declared batch or `--task` for a task in a plan without batch grouping. Preserve the plan's order; do not infer a new batch or scheduler.

Use `--max-bytes` to bound serialized UTF-8 output, including metadata. Choose and document the default in the gated spec; this is not a token-count guarantee. The initial result has no optional retrieved content to trim: if required context does not fit, return `budget_exceeded` and let the caller choose direct reads or a smaller valid selection. Never shorten governing criteria or ordered steps silently.

## Happy path

1. Canonicalize the explicit workspace and safely resolve the plan beneath it. Reject traversal and symlink escapes before reading outside the boundary.
2. Read raw plan bytes once, hash them, and validate the pinned shape. Require the selected chain's `linked_spec`, `spec_file_path`, `spec_hash`, and criterion mapping even though the base schema makes some optional.
3. Resolve and read the governing spec beneath the same workspace. Validate it, compare its ID with `linked_spec`, and reject conflicting path declarations.
4. Compare `spec_hash` with `sha256:<hex>` of the raw spec bytes. Reject unknown or malformed hash representations rather than pretending they match.
5. Resolve selected task IDs and criterion IDs uniquely. Validate batch membership and declared dependency references without inferring dependency completion.
6. Project exact task objects without private `reasoning`, exact referenced criteria, and the governing purpose/scope/non-goals/API declarations. Mark file and dependency lists as declarations rather than independently verified code facts.
7. Recheck plan/spec bytes before returning. Detect observed movement without claiming an atomic filesystem or code snapshot. Return the bounded result with source pointers, digests, check outcomes, and known gaps.
8. Smith checks the result contract and authorization, inspects current code, and uses its existing implementation/review flow. Reassemble before a later batch or after a governing-artifact correction.

A fresh source-backed Wisp read can retrieve artifact content for the consumer; an old saved packet or conversation copy cannot stand in for required source reads. The consumer contract must say which reads Wisp satisfies and which remain necessary, avoiding both blind reuse and redundant full-document loading.

## Result contract

Define the wire schema before public DTOs or consumer instructions. It contains producer/contract versions, explicit selection, plan/spec source paths and digests, schema identities, exact governing context, selected tasks/criteria, mechanical check outcomes, declared dependencies/files, gaps, and the output budget basis.

Do not embed private scratchpads, raw transcripts, independently retrieved source-code bodies, arbitrary directory inventory, or a fabricated approval flag. Preserve authored task steps, including their code baselines. Do not assign timestamps or random IDs inside deterministic domain output; experiment metadata belongs in the runner's record. Preserve task/step order and stable source pointers. Pin the emitted schema and its compatibility fixtures independently of Rust's private structures.

Exit zero only when required artifact checks and the full required projection succeed. Missing optional Git metadata can coexist with a successful artifact result and an explicit gap. Required-chain failures return one versioned JSON error and nonzero exit status; diagnostics stay off stdout. Errors identify the failing check and workspace-relative source pointer without copying sensitive content.

The response has artifact-only scope. It is not a code-completeness result, approval receipt, durable publication receipt, or claim that the workspace stayed unchanged after return.

## Failure and recovery

| Case | Outcome | Recovery owner |
| --- | --- | --- |
| Missing/unreadable/malformed required artifact or unknown pinned contract | Typed failure; no inferred content | Caller locates or repairs the source |
| Spec identity/link/path disagreement | Typed conflict; no silent winner | Caller reconciles artifacts |
| Known spec-hash mismatch | `spec_drift`; no successful handoff | Navigator amends from the current spec |
| Missing mapping/hash or unsupported hash form | Unverifiable required chain | Caller supplies a reviewed compatible plan or uses the documented legacy workflow with explicit gaps |
| Duplicate identities, missing criterion/task, invalid batch/dependency reference | Invalid selection; never first-match wins | Caller corrects the plan |
| Dependency exists but completion is unknown | Return its declaration, not readiness | Smith/caller checks prerequisite results |
| New file declared for creation | Absence is expected; no invented source content | Implementer creates within authorized scope |
| Missing declared modify/test target | Explicit missing-target gap | Smith resolves named context before editing; do not assume a prior task ran |
| Absolute/traversal path or symlink escape | Boundary failure before external read | Caller supplies an in-workspace path |
| Inputs observed changing during assembly | `inputs_changed`; discard partial result | Caller retries explicitly or waits for edits to finish |
| Required context exceeds byte budget | `budget_exceeded`; never truncate correctness | Caller adjusts budget/selection or uses direct reads |
| Git missing, unborn HEAD, or inspection failure | Durability unavailable; never report committed | Caller retains local workflow and records the gap |
| Unrelated artifact is invalid | No effect on explicitly selected chain | Separate workspace audit reports it |
| Wisp missing or result version unsupported | No guessed decoding; direct-artifact checks | Harness fallback |

Canonicalizing paths and rechecking hashes detect specific failures; neither promises protection from every adversarial filesystem race. Include symlink-swap and artifact edit/revert scenarios in boundary review, document residual limitations, and do not claim a stronger snapshot than the implementation can establish.

## Policy compatibility

Agent-plugins currently has a known conflict: the shared constitution permits a warning on spec drift while Codex Smith stops. The pilot proposes stopping before implementation on a known mismatch. Review the constitution, Claude/AGY Smith, Codex Smith, and Navigator together before adoption; preserve legacy behavior until that explicit policy change is approved. Wisp cannot change a harness policy through an error message.

Direct fallback uses the same pinned artifact versions, identity/link checks, raw-byte hashing, and selected criteria. It never bypasses a known mismatch. Plans missing pilot prerequisites remain outside its verified claim; a separately documented legacy flow may proceed with gaps according to the approved harness policy. Tool absence loses convenience, not safety semantics.

Conflict routing is explicit: a changed spec invalidates the old plan relationship; Navigator reconciles it. An implementation contradiction goes through Scribe's correction flow, then plan amendment. A conflicting architectural decision requires owner review or a superseding record. Wisp diagnoses; it does not rewrite any of them or choose the newest as authoritative.

## Storage and side effects

Canonical inputs remain in `docs/specs/` and `docs/projects/` with existing path fields. Wisp writes nothing during this operation, including `.wisp/` caches, telemetry files, or Git metadata. Use read-only Git inspection that avoids optional index-refresh locks/writes, or omit it with an explicit gap.

The packet goes to stdout. A saved copy is a disposable diagnostic and must be revalidated against current inputs before reuse. Agent memory is non-authoritative and never stores the sole copy of a decision.

Fixture definitions and expected checks are versioned. A runner stores each actual run under a separate ignored/temporary directory, with fixture revision/digests, starting workspace state, tool/plugin revisions, harness/model/mode, selection, commands, output, terminal status, final diff, and independently checked criteria. Include tokens/cost only when observed; unavailable measurements remain gaps. Keep raw sensitive transcripts out of canonical artifacts.

## Bounded implementation batches

| Batch | Deliverable | Proof |
| --- | --- | --- |
| B1: contract and selected-chain library | Pinned wire schema, safe path resolution, shape/link/hash checks, exact projection, typed errors | Table-driven happy/error fixtures; no unrelated graph scan |
| B2: CLI boundary | Proposed command, selectors, JSON/exit behavior, byte budget, input-movement checks | Real-binary tests; unchanged files/Git state; no partial or oversized success |
| B3: plugin consumer (agent-plugins) | Optional Smith route, explicit freshness/approval boundaries, policy-equivalent fallback in both harnesses | Representative consumer fixtures and cross-harness change record |
| B4: small value experiment | Direct-artifact and Wisp-assisted runs on frozen tasks with independent checks | Real execution, terminal results, reproducible run record; missing checks cannot pass |

First validate WISP-001's existing foundation and document REQ-WISP-002's registry implementation. Create a new requirement and gated spec/plan for this slice; leave WISP-001's scope, existing schema versions, and WISP-003's later code-evidence correctness requirements intact. New API signatures are design proposals until grounded in the implementation; do not copy guessed signatures into an existing-code API surface.

No new permanent agent role is needed. The existing implementer owns a cohesive batch, and a reviewer checks its diff and evidence. Parallelize independent fixture work only after the contract is fixed; the primary agent owns interface decisions and reconciliation.

## Integration and value gates

The integration gate exercises the real binary and both harness consumers. Generate controlled modifications from a valid plan/spec pair: change bytes, break links, duplicate IDs, remove prerequisites, escape paths, move inputs, and cross the output budget. The oracle is the specified result/exit status and unchanged canonical inputs, not the producer's self-report. Check exact criterion text, step order, private-field exclusion, and stable serialization.

The value gate uses a few frozen real implementation tasks. Compare direct-artifact access with the same workflow receiving Wisp context; keep fixture, starting revision, model, harness, plugin versions, and verification commands fixed. Capture a baseline failure before running the agent, then independently inspect final files and terminal project-native checks. Do not execute arbitrary shell text found inside a packet automatically; the runner explicitly selects its verification commands and sandbox policy.

Measure completed criteria, regressions, mechanical preparation calls, inconsistencies caught before edits, latency, and observed cost per successful task. A replay validates a protocol fixture but is not a new agent-outcome trial. Hand-reviewed small experiments justify the next slice, not a general performance claim.

Stop if the consumer bypasses known inconsistencies, required context is lost, expected checks are missing, or final correctness regresses. Iterate if the checks work but the packet adds duplicate reads or no practical benefit. Expand only after the handoff proves useful; select one observed missing capability, not the whole roadmap.

## Later tool interactions

| Tool | Next entry condition | Handoff |
| --- | --- | --- |
| Monokl | A real task needs code evidence beyond declarations and a working provider interface exists | One operation with source/version/config provenance, scope, precision, resolution, and explicit failure; retain artifact-only fallback |
| Lumen | Actual pilot run evidence exists and manual analysis needs repeatable ingestion | Session annotations with verified correlation; observed/derived/modeled measurements remain distinct |
| Prism | The narrow execution path actually runs a fixture and independently verifies all required checks | Reuse the experiment definition and outcome oracle; synthetic/demo output stays labelled |
| Michi | Rendering is a measured problem | Derive presentation from the same result and prove semantic equivalence; D-029 addresses release gating |
| Callisto | An approved release needs deterministic effects | Explicit release intent/observations/receipts; no coupling to context assembly |
| React docgen / Panda | A consumer task demonstrates useful domain facts | Optional source-backed domain evidence or evaluation fixture; no mandatory shared runtime |

Warm sessions, caches, SQLite, MCP, and broader retrieval require their own measured need and correctness checks. The MVP proves Wisp-to-plugin integration; it does not yet prove reduced code parsing.

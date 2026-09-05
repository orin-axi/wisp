# Wisp

**Local-first project intelligence for coding agents and humans.**

*Makes a repository's durable project knowledge usable without relying on a conversation's context window.*

**Status:** local WISP-001 vertical slice in progress; not published.

---

## What it does

Wisp joins four kinds of evidence into one bounded, cited answer:

| Evidence | Source |
| :--- | :--- |
| Canonical work artifacts | Git-tracked specifications, plans, architecture models, decisions |
| Repository state and history | Git worktree and commit evidence |
| Structural code evidence | [Monokl](../monokl/README.md) |
| Derived acceleration | an explicitly rebuildable local index and briefing cache |

Wisp is not an agent runtime, a replacement for Git, a code parser, or an opaque "AI memory" product. It is a library with a CLI first and an MCP server as a thin later surface. Its job is to answer evidence-backed project questions and prepare a small, relevant context package for a particular stage of work.

## Available local commands

The first implemented slice deliberately covers only portable `spec@1` JSON artifacts. All success and failure responses are one deterministic JSON object on standard output.

```text
wisp artifact validate <candidate.json|->
wisp artifact persist <candidate.json|-> --workspace <workspace>
wisp artifact get <SPEC-ID> --workspace <workspace>
wisp artifact status <SPEC-ID> --workspace <workspace>
```

- **`persist`** — validates before it writes, adds the canonical `spec_file_path`, and atomically writes only `docs/specs/<SPEC-ID>.json`. Reports a `sha256:` hash over the final file bytes and never commits Git changes.
- **`get`** — revalidates the stored JSON.
- **`status`** — reports `absent`, `uncommitted`, or `clean` without implying that a commit was made.
- **Errors** — JSON by default for harnesses and automation; `--format human` renders a structured `miette` diagnostic on standard error during interactive work.

Monokl integration, derived storage, vector search, Michi rendering, and MCP remain intentionally out of this first slice.

## The central rule

The cache is never the authority.

```text
Git-tracked artifacts + Git state + Monokl code evidence
                         │
                         ▼
               Wisp's rebuildable index/cache
                         │
                         ▼
             CLI / MCP evidence-backed response
```

- If `.wisp/` is deleted, Wisp must be able to reconstruct it from the workspace.
- If Wisp is absent, a harness must still be able to read the documented JSON artifacts directly and carry out the portable baseline workflow.

## The intended user experience

```text
Claude / Codex / OpenCode / a human
              │
              ▼
      wisp brief implement --plan PLAN-014
              │
              ▼
  small, cited package: plan + spec + relevant invariants
  + affected symbols/tests + current Git delta + next actions
```

The same capability will eventually be exposed as an MCP tool such as `wisp_brief`. The CLI JSON result is the primary contract; TOON/KV rendering is an optimized presentation, not a storage or mutation format.

## Reading order

| # | Document | Covers |
| :--- | :--- | :--- |
| 1 | [Vision and boundaries](docs/01-vision-and-boundaries.md) | What Wisp is and is not |
| 2 | [Architecture and contracts](docs/02-architecture-and-contracts.md) | The full contract: crates, evidence model, persistence, MCP |
| 3 | [Delivery plan and acceptance gates](docs/03-delivery-plan.md) | Milestones 0–6 and what closes each |
| 4 | [Decision log and open questions](docs/04-decisions-and-open-questions.md) | D-001 through D-027; Q-007 onward still open |
| 5 | [Ten-phase build sequence](docs/05-ten-phase-build-plan.md) | Codex's finer-grained ordering within the milestones above |
| 6 | [Research brief](docs/06-research-brief.md) | The prior art and papers behind D-009 through D-021 |
| 7 | [Build and release](docs/07-build-and-release.md) | How six separate repositories resolve, build, and publish in dependency order |

| Also | Covers |
| :--- | :--- |
| [`docs/spec/wisp-contracts/01-contracts.md`](docs/spec/wisp-contracts/01-contracts.md) | `crates/wisp-contracts`, a workspace member published from this repository: every shared type, its wire form, and its stability policy (D-027) |
| [`ARCHITECTURE.md`](ARCHITECTURE.md) | Crate status and current gaps |
| [`PRINCIPLES.md`](PRINCIPLES.md) | What belongs here |
| [`AGENTS.md`](AGENTS.md) | Commands and non-negotiables for agents |
| [`docs/spec/WISP-001/00-overview.md`](docs/spec/WISP-001/00-overview.md) | The active implementation unit |

## Related projects

| Project | Role | Boundary |
| :--- | :--- | :--- |
| **Monokl** | AST-aware code evidence: code search, symbols, definitions, references, precision metadata | Wisp must not duplicate its parser, AST cache, or code index |
| **Michi** | Token-efficient agent output: TOON, KV, hints, MCP result assembly, truncation | `git` + `rev` dependency during coordinated development (D-024). The dependency runs one way — Michi links nothing in Wisp, and `wisp-output` converts into Michi's own rendering types (D-006) |
| **Callisto** | Precedents and reusable permissively licensed pieces for `gix`-backed VCS access and crash-safe writes | License compatibility must be checked before code reuse |
| **Lumen** | Observes agent sessions, cache use, and retrieval loops | An evaluation/telemetry companion, never project truth |
| **Prism** | Evaluates whether Wisp context improves task success, correctness, latency, and cost across harnesses | The quality gate, not a source of project state |
| **Wisp Plugins** (`agent-plugins`) | The ten-plugin agent ecosystem: source of the versioned artifact schemas Wisp validates, and of the `scribe:exit-gate` / `navigator:challenger` gates its own specs and plans pass through | Schemas are vendored into Wisp at a pinned revision with a checksum, never read from a mutable sibling checkout (D-010) |

See [Architecture and contracts](docs/02-architecture-and-contracts.md) for the precise boundaries.

## License

`wisp-contracts` and `wisp-model` are `MIT`, so a third-party harness plugin can embed the interchange types with no further obligation. Every other crate is `FSL-1.1-MIT`, which converts to MIT two years after each release. Michi and Monokl are `FSL-1.1-MIT` as well, so the suite links without conflict. D-021 records why.

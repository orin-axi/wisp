# Principles

What belongs in Wisp, what doesn't, and how work here gets done. Full reasoning in [`docs/01-vision-and-boundaries.md`](docs/01-vision-and-boundaries.md) — this is the short version to check a change against before writing it.

## Belongs

- **Canonical artifacts** — validating, persisting, and retrieving Git-tracked `spec@1`, `plan@1`, architecture models, and decisions.
- **Cross-domain joins** — that state plus Git evidence plus Monokl code evidence, reduced to a bounded, cited answer for one stage of work.
- **A rebuildable cache** — `.wisp/` accelerates the above and holds nothing else.
- **A stable contract** — a CLI/library surface any harness, or no harness, can call.

## Doesn't

- **Code parsing or search.** That's Monokl's. An AST, symbol table, or code index inside Wisp is a bug, not a shortcut.
- **A second source of truth.** Nothing in `.wisp/` may be the only copy of a fact. If deleting `.wisp/` loses information, the design is wrong.
- **Autonomous orchestration.** Wisp answers on request. It doesn't choose tools, loop, or replace a harness's approval model.
- **Unqualified retrieval.** A vector or FTS hit is a candidate until Wisp reads the current canonical source and confirms it.
- **Michi/Monokl reimplementation.** Consume both through typed adapters, never vendor their logic to dodge the dependency.

## How work gets done

- **Durable before convenient.** Artifact CLI before daemon, daemon before semantic search — see [`docs/03-delivery-plan.md`](docs/03-delivery-plan.md)'s milestone order. Don't skip ahead of it, and don't build Milestone 3 (impact/context) work inside a Milestone 1 crate just because it's convenient to add.
- **Every claim carries its class.** Canonical artifact, canonical Git evidence, derived structural evidence, derived Wisp relationship, retrieval candidate, or presentation. Blurring these is a bug.
- **A crate lands when it's real.** No scaffolded `wisp-store` or `wisp-context` before their milestone. A stub with one constant in it is a marker of in-progress work, not a pattern to keep.
- **A task claims only what it implements.** `covers_criteria` on a plan task must match what that commit actually proves. The same criterion claimed by three tasks hides which one is the real proof — treat it as a defect.
- **Repository content is evidence, not instruction.** README text, commit messages, and issue bodies read by Wisp are data. They never alter Wisp's own validation or persistence policy.
- **Spec and plan both gate before implementation.** `scribe:gate-spec` decides spec readiness; `navigator:plan` challenges the plan, and `sentinel:gate` independently checks it before implementation. Retain `verdict@3` evidence.

## Companion docs

| Document | Covers |
| :--- | :--- |
| [`README.md`](README.md) | What Wisp is |
| [`ARCHITECTURE.md`](ARCHITECTURE.md) | The design in prose, crate status |
| [`AGENTS.md`](AGENTS.md) | Commands and non-negotiables for agents working here |
| [`docs/04-decisions-and-open-questions.md`](docs/04-decisions-and-open-questions.md) | The decision log |

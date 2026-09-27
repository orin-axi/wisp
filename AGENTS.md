# Wisp — Agent Instructions

Architecture, invariants, and task-runner workflows for agents (Claude, Codex, Cursor, Copilot) working in this repo.

## Commands

| Command | Does |
| :--- | :--- |
| `just` / `just ci` (default) | Run the current docs-only CI check. |
| `just docs-lint` | Check Markdown house style, fences, decision references, and stale names. |

The tracked branch has no Rust workspace or Moon configuration. Add Rust checks to `just ci` and CI when the workspace is committed; do not treat docs-only CI as code verification. For local untracked Rust work, use Cargo directly and report those results separately.

## Architecture

| Crate | Responsibility |
| :--- | :--- |
| `wisp-model` | IDs, DTOs, provenance. Depends on nothing else here. |
| `wisp-schema` | Vendored, pinned JSON Schemas; validation. |
| `wisp-artifacts` | Canonical paths, atomic persist, hashing, local Git state. |
| `wisp-cli` | The `wisp` binary. JSON in, JSON out, no domain logic. |
| `wisp-fixtures` | Shared fixture data and test helpers. |

Full picture, crate status, and current gaps: [`ARCHITECTURE.md`](ARCHITECTURE.md). What belongs here and why: [`PRINCIPLES.md`](PRINCIPLES.md).

## Non-negotiables

1. **`unsafe_code = "forbid"`, `unwrap_used`/`expect_used` deny** — workspace lints, all crates. No exceptions in lib code.
2. **Atomic writes only.** Every canonical artifact write goes through a same-directory tempfile + rename. Never write a canonical target in place.
3. **The cache is never the authority.** Nothing in `.wisp/` may be the only copy of a fact — see `PRINCIPLES.md`.
4. **Implement only what the current gated plan's `covers_criteria` requires.** A spec's `non_goals` are binding, not aspirational. If a task looks like it needs scope the spec excludes, stop and raise it — don't implement it and explain later. This bit us on WISP-001: `wisp-artifacts` shipped multi-artifact-type discovery and context assembly, explicitly excluded by that spec's non-goals, before anyone gated it. See `docs/spec/WISP-001/02-decisions.md`.
5. **Spec and plan both gate before implementation.** Use `scribe:gate-spec` for the spec, `navigator:plan` to challenge the plan, and `sentinel:gate` for an independent plan verdict. Without persisted `verdict@3` evidence, treat a claimed gate pass as unverified.
6. **A plan task claims only the criteria it implements.** Don't list `covers_criteria` for work a later task actually does.
7. **Every crate ships a README, and every new crate lands with its own.** State what it does, what depends on it, and its current status (stub / in progress / shipping).
8. **No emoji in docs or code comments.** Keep it technical and scannable.
9. **Doc comments on every `pub` item.**

## Documentation map

| Document | Covers |
| :--- | :--- |
| [`README.md`](README.md) | Orientation |
| [`ARCHITECTURE.md`](ARCHITECTURE.md) / [`PRINCIPLES.md`](PRINCIPLES.md) | Design and philosophy |
| [`docs/01-vision-and-boundaries.md`](docs/01-vision-and-boundaries.md) through [`docs/04-decisions-and-open-questions.md`](docs/04-decisions-and-open-questions.md) | The full product contract |
| [`docs/spec/WISP-001/`](docs/spec/WISP-001/00-overview.md) | Prose spec for the active implementation slice |
| Each `crates/*/README.md` | Per-crate detail |

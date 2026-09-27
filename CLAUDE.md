# Wisp Codebase Guide for Claude

This repository follows the centralized agent guidelines in [`AGENTS.md`](AGENTS.md).

## Quick reference

| Command | Does |
| :--- | :--- |
| `just` / `just ci` (default) | Current docs-only check. |
| `just docs-lint` | Markdown house-style check. |

The Rust workspace is not tracked yet. Use Cargo directly for local Rust work and do not describe the docs-only check as code verification.

## Top invariants

1. `unsafe_code = "forbid"`, `unwrap_used`/`expect_used` deny — no exceptions in lib code.
2. Canonical artifact writes are atomic (tempfile + rename), always.
3. Implement only what the current gated plan's `covers_criteria` requires — a spec's `non_goals` are binding. Don't build ahead of the plan; raise scope questions instead of quietly answering them in code.
4. Spec and plan both gate (`scribe:exit-gate`, `navigator:challenger`) before implementation starts.

See `AGENTS.md` for the full list.

# Wisp Codebase Guide for Claude

This repository follows the centralized agent guidelines in [`AGENTS.md`](AGENTS.md).

## Quick reference

| Command | Does |
| :--- | :--- |
| `just` (default) | fmt-check + lint + test + audit + doc-check. Run before every commit. |
| `just test` / `just lint` / `just fmt` | Scoped equivalents. |
| `cargo test -p <crate>` / `cargo clippy -p <crate>` | One crate — use these directly, not `moon run <project>:test`. |

## Top invariants

1. `unsafe_code = "forbid"`, `unwrap_used`/`expect_used` deny — no exceptions in lib code.
2. Canonical artifact writes are atomic (tempfile + rename), always.
3. Implement only what the current gated plan's `covers_criteria` requires — a spec's `non_goals` are binding. Don't build ahead of the plan; raise scope questions instead of quietly answering them in code.
4. Spec and plan both gate (`scribe:exit-gate`, `navigator:challenger`) before implementation starts.

See `AGENTS.md` for the full list.

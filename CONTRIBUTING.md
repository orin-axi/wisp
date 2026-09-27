# Contributing to Wisp

Contributions are welcome. This guide covers the development environment, the invariants every change must keep, and the pull request workflow. By participating you agree to the [Code of Conduct](./CODE_OF_CONDUCT.md). Found a security issue? See [SECURITY.md](./SECURITY.md) instead of opening a public issue.

---

## 1. Development environment

### Prerequisites

- **Docs checks**: install `just` and `rg`.
- **Rust**: the local WISP-001 slice uses Rust 1.96 and edition 2024, but its workspace and toolchain pin are not tracked on this branch.

### Build and test

```bash
just            # current docs-only CI check
just docs-lint  # Markdown house style, fences, decision references, stale names
```

For local untracked Rust work, run Cargo checks directly. Add the workspace and its checks together when WISP-001 is committed; a passing docs check does not validate code.

### Before opening a PR

CI runs `just ci`. Run it locally first; it currently checks tracked documentation only.

---

## 2. Engineering invariants

1. **Safe Rust only.** `unsafe_code = "forbid"`, `unwrap_used`/`expect_used` deny — workspace lints, every crate, no exceptions in library code.
2. **Atomic writes only.** Every canonical artifact write is a same-directory tempfile plus rename. Never write a canonical target in place.
3. **The cache is never the authority.** Nothing under `.wisp/` may be the only copy of a fact. See [`PRINCIPLES.md`](./PRINCIPLES.md).
4. **Implement only what the current gated plan's `covers_criteria` requires.** A spec's `non_goals` are binding. If a task needs scope the spec excludes, stop and raise it.
5. **Spec and plan both gate before implementation.** `scribe:exit-gate` on the spec, `navigator:challenger` on the plan. No `verdict@1` on file means the plan is provisional.
6. **Permissive core stays permissive.** `wisp-contracts` and `wisp-model` are `MIT` and must not depend on any `FSL-1.1-MIT` crate, Tokio, MCP types, Monokl types, SQLite, or CLI formatting.
7. **Docs are unwrapped and unpadded.** One paragraph per line, no emoji, no filler. `just docs-lint` enforces the mechanical part.

The full list, with the reasons, is in [`AGENTS.md`](./AGENTS.md).

---

## 3. Pull request workflow

1. **Branch** with a descriptive name: `feat/…`, `fix/…`, `docs/…`, `chore/…`.
2. **Tests prove criteria.** Every task's tests name the acceptance criteria they cover; mutation testing (`cargo-mutants`) checks the tests would catch real faults.
3. **Verify locally** with `just ci` and any checks needed for changed code. Expand CI when that code enters the repository.
4. **Conventional commits**: `feat:`, `fix:`, `docs:`, `refactor:`, `test:`, `chore:`. The message explains why; the diff already shows what.
5. **Cross-repo dependencies** on Monokl and Michi are `git` + `rev` in committed manifests. A local `[patch]` for path development lives in gitignored `.cargo/config.toml` and never in a commit — see [`docs/07-build-and-release.md`](./docs/07-build-and-release.md).

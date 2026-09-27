# Contributing to Wisp

Contributions are welcome. This guide covers the development environment, the invariants every change must keep, and the pull request workflow. By participating you agree to the [Code of Conduct](./CODE_OF_CONDUCT.md). Found a security issue? See [SECURITY.md](./SECURITY.md) instead of opening a public issue.

---

## 1. Development environment

### Prerequisites

- **Toolchain via proto**: `.prototools` pins Rust, moon, just, and cargo-deny. Run `proto use` once.
- **Rust**: 1.96, edition 2024, pinned in `rust-toolchain.toml`.
- **Preferred CLI tools**: `rg`, `fd`, `eza`, `bat`.

### Build and test

There is no `justfile` or `docs-lint` recipe in the current working tree. Use the available Cargo commands; the commands described by WISP-001 and CI remain implementation work, not a functioning local entry point.

```bash
cargo fmt --all --check
cargo clippy --workspace --all-targets -- -D warnings
cargo test --workspace
cargo doc --workspace --no-deps
```

For one crate use `cargo test -p <crate>` or `cargo clippy -p <crate>` directly, not `moon run <project>:test` — moon's per-project fan-out serializes on the shared `target/` build lock.

### Before opening a PR

CI currently invokes `just ci`, but its recipe file is absent. Restore and verify that task surface under WISP-001 before claiming CI parity. Run the available checks and report blocked checks explicitly.

---

## 2. Engineering invariants

1. **Safe Rust only.** `unsafe_code = "forbid"`, `unwrap_used`/`expect_used` deny — workspace lints, every crate, no exceptions in library code.
2. **Atomic writes only.** Every canonical artifact write is a same-directory tempfile plus rename. Never write a canonical target in place.
3. **The cache is never the authority.** Nothing under `.wisp/` may be the only copy of a governing fact. See [Vision and boundaries](docs/01-vision-and-boundaries.md).
4. **Implement only what the current gated plan's `covers_criteria` requires.** A spec's `non_goals` are binding. If a task needs scope the spec excludes, stop and raise it.
5. **Spec and plan both gate before implementation.** Preserve review evidence and owner authorization; schema validity, a commit, or this planning brief does not imply approval. Do not assume an obsolete verdict version or invent an approval receipt.
6. **Permissive core stays permissive.** `wisp-model` must not depend on a restrictively licensed domain crate, Tokio, MCP types, Monokl types, SQLite, or CLI formatting. A separate `wisp-contracts` crate is not implemented or required by the pilot.
7. **Docs are unwrapped and unpadded.** One paragraph per source line, no emoji, no filler. A docs-lint recipe is not yet available; inspect this rule directly until one exists.

There is no root `AGENTS.md` in this checkout. Use the existing [architecture boundaries](docs/02-architecture-and-contracts.md), [decision log](docs/04-decisions-and-open-questions.md), and [MVP brief](docs/05-implementation-handoff-mvp.md); do not mistake a missing instruction file for an implemented enforcement mechanism.

---

## 3. Pull request workflow

1. **Branch** with a descriptive name: `feat/…`, `fix/…`, `docs/…`, `chore/…`.
2. **Tests prove criteria.** Every task's tests name the acceptance criteria they cover; mutation testing (`cargo-mutants`) checks the tests would catch real faults.
3. **Verify locally** with the available Cargo checks. Once `just ci` exists and has been verified, use it for CI parity.
4. **Conventional commits**: `feat:`, `fix:`, `docs:`, `refactor:`, `test:`, `chore:`. The message explains why; the diff already shows what.
5. **Cross-repo dependencies** are absent from the pilot. If a later feature adds one, record an immutable source or compatible release and keep local overrides out of published builds. The proposed Michi release-gate change is D-029; no `docs/07-build-and-release.md` exists yet.

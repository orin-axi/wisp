default: ci-fast

build:
    moon run :build

test:
    moon run :test

lint:
    cargo clippy --workspace --all-targets -- -D warnings

fmt:
    moon run :format

fmt-check:
    moon run :format-check

audit:
    cargo deny check advisories

doc-check:
    RUSTDOCFLAGS="-D warnings" cargo doc --workspace --no-deps

# House-style lint for markdown: filler words, fences, D-/Q- references, stale names. Read-only.
docs-lint:
    scripts/docs-lint.sh

pre-commit: fmt-check

pre-push: fmt-check lint

ci-fast: fmt-check lint test audit doc-check docs-lint

ci: ci-fast

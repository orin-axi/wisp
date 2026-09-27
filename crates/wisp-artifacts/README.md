# wisp-artifacts

Canonical artifact path resolution, atomic persistence, hashing, and local Git-state classification.

## Overview

`spec@1` operations (WISP-001 scope):

- `spec_relative_path(id)` — the only valid `docs/specs/<id>.json` destination for an ID.
- `persist_spec(workspace, candidate)` — validate, set `spec_file_path`, write atomically (same-directory tempfile + rename), hash the final bytes on disk, never commit.
- `get_spec(workspace, id)` — load, revalidate, hash, classify local state.

Also shipped, ahead of spec (see [`../../ARCHITECTURE.md`](../../ARCHITECTURE.md#ahead-of-spec)):

- `discover_graph(workspace)` — find and revalidate every canonical artifact across all five contract types, resolve declared links (`linked_requirement`, `linked_research`, `linked_spec`), and report broken links as non-fatal issues.
- `assemble_context(workspace, contract, key)` — one-hop context package (root artifact + direct links + Git evidence) for a requested artifact.
- `git_evidence` / `local_state` — shell out to `git status`/`rev-parse`; unavailable Git reports a reason code rather than guessing.

Depends on `wisp-model` and `wisp-schema`.

## Status

Shipping, with tests for the `spec@1` round-trip, absent lookup, invalid-input rejection, and write-failure atomicity. The graph and context functions are untested by any acceptance criterion — they are not in WISP-001's `api_surface`.

## License

`FSL-1.1-MIT` — the Wisp suite license (D-021). Converts to MIT two years after each release.

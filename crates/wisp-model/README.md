# wisp-model

Stable domain contracts shared by every other Wisp crate.

## Overview

- `ArtifactId` — path-safe identifier; rejects empty input and anything that could escape a canonical path (`/`, `\`, `.`, `..`).
- `ArtifactType` — the artifact contracts Wisp implements (`SpecV1` today).
- `LocalArtifactState` — `Absent` / `Uncommitted` / `Clean` in the local Git worktree.
- `ArtifactRecord` — id, type, path, content hash, state, and the revalidated parsed artifact.
- `PersistenceReceipt` — id, type, path, content hash, state; returned after a persist.

Depends on nothing else in the workspace, and must not depend on Tokio, MCP types, Monokl types, SQLite, or CLI formatting — see [`../../PRINCIPLES.md`](../../PRINCIPLES.md).

## Status

Shipping. `ValidatedSpec` lives in `wisp-schema` instead of here — see that crate's README.

## License

`MIT` — permissive, alongside `wisp-contracts`, so a third-party harness plugin can embed the DTOs (D-021).

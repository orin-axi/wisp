# API and CLI

## wisp-model

| Type | Purpose |
| --- | --- |
| `ArtifactId` | path-safe identifier |
| `ArtifactType` | `SpecV1` today |
| `LocalArtifactState` | `Absent` / `Uncommitted` / `Clean` |
| `ArtifactRecord` | id, type, path, content_hash, state, parsed artifact |
| `PersistenceReceipt` | id, type, path, content_hash, state |

## wisp-schema

```rust
fn validate_spec_json(input: &[u8]) -> Result<ValidatedSpec, SpecValidationError>;
fn validate_spec_value(value: Value) -> Result<ValidatedSpec, SpecValidationError>;
```

`ValidatedSpec { id, value }` and `SpecValidationError` (`InvalidJson` with a source span, `SchemaDefinition`, `SchemaViolation`, `UnsafeId`) live here rather than in `wisp-model`. The JSON spec's `api_surface` named them as return and error types without pinning which crate owns them; this is where they landed.

## wisp-artifacts

```rust
fn persist_spec(workspace: &Utf8Path, candidate: &[u8]) -> Result<PersistenceReceipt, ArtifactError>;
fn get_spec(workspace: &Utf8Path, id: &ArtifactId) -> Result<ArtifactRecord, ArtifactError>;
```

- **`persist_spec`** validates, sets `spec_file_path`, writes atomically (same-directory tempfile + rename), and hashes only the bytes read back from disk — never the in-memory buffer, so a partial write cannot be reported as a false positive.
- **`get_spec`** loads, revalidates, hashes, and classifies local Git state.

Neither creates a commit.

## wisp-cli

```bash
wisp artifact validate <candidate.json|->
wisp artifact persist <candidate.json|-> --workspace <path>
wisp artifact get <id> --workspace <path>
wisp artifact status <id> --workspace <path>
```

Every command maps a library result to one deterministic JSON object and a nonzero exit on failure. `status` is absent from `docs/specs/WISP-001.json`'s `acceptance_criteria` — see [02-decisions.md](02-decisions.md).

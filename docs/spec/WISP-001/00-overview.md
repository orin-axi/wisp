# WISP-001 spec

Prose companion to [`../../specs/WISP-001.json`](../../specs/WISP-001.json) and [`../../projects/WISP-001.json`](../../projects/WISP-001.json). The JSON is the machine-checkable contract; this is the reading-order detail.

## Reading order

| Doc | Covers |
| --- | --- |
| [00-overview.md](00-overview.md) | This file — goal, scope, non-goals, consumers |
| [01-api-and-cli.md](01-api-and-cli.md) | `wisp-model` types, `wisp-schema`/`wisp-artifacts` operations, `wisp-cli` commands |
| [02-decisions.md](02-decisions.md) | Defects found in review, open questions, reasoning not obvious from the JSON |

| Adjacent | Covers |
| --- | --- |
| [`../wisp-contracts/01-contracts.md`](../wisp-contracts/01-contracts.md) | The cross-repo vocabulary crate. Not in WISP-001's scope; `wisp-model` links it from M0 onward |
| [`../../07-build-and-release.md`](../../07-build-and-release.md) | Cross-repo dependency resolution, the moon inputs contract, and release order |

## Goal

Prove the durable, portable artifact contract — validate, persist, retrieve, hash, local Git state — for one artifact type (`spec@1`), before any derived cache, code intelligence, or harness-specific interface exists. This is M0 and M1 of [`../../03-delivery-plan.md`](../../03-delivery-plan.md) scoped to a single vertical slice.

## Scope

`crates/wisp-model`, `wisp-schema`, `wisp-artifacts`, `wisp-cli`, `wisp-fixtures`:

1. load one vendored `spec@1` JSON Schema pinned to a recorded `agent-plugins` revision
2. validate a candidate against it
3. resolve and atomically write a valid candidate to `docs/specs/<id>.json`
4. compute a SHA-256 over the final raw bytes
5. retrieve a persisted artifact by ID, revalidate it, classify its local Git state (absent / uncommitted / clean)

Moon defines the crate graph; Just exposes build, test, lint, format, audit, and CI.

## Non-goals

- Any artifact type other than `spec@1`
- Git commits, branches, tags, remote pushes
- Monokl queries, SQLite state, FTS, vectors, briefing compilation, impact analysis
- MCP transport, TOON rendering, a required Michi dependency
- Replacing the source `agent-plugins` schema registry with a new distribution system

`wisp-artifacts` and `wisp-schema` currently exceed this — see [`../../../ARCHITECTURE.md`](../../../ARCHITECTURE.md#ahead-of-spec) and [02-decisions.md](02-decisions.md).

## Who consumes this

Any harness (Claude, Codex, OpenCode) or a human running `wisp` directly. No harness-specific integration exists yet — the CLI's JSON contract is the only interface.

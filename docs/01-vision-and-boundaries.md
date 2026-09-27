# Wisp: Vision and Boundaries

## Problem

Coding-agent work is long-lived while an individual context window is not. Important facts become fragmented across source code, Git history, plans, specifications, architecture decisions, tests, and prior agent sessions. A future agent should not have to rediscover all of that material, nor should it receive an indiscriminate dump of documents that consumes its context budget.

The failure modes are familiar:

- an implementation agent works from a stale plan after the spec changed;
- an agent creates a duplicate abstraction because it did not find the architecture decision that designated the canonical one;
- a review does not know which acceptance criteria a change was meant to satisfy;
- a model treats an embedding hit or an old conversation summary as proof;
- different harnesses carry work forward through incompatible private state.

Wisp addresses these as a project-information problem, not a prompt-writing problem.

## Product thesis

Wisp is an **evidence-backed project intelligence layer**.

It answers questions such as:

- What approved work artifact governs this change?
- Which symbols, modules, tests, and invariants are relevant to this plan?
- Which specifications and plans are affected by this Git diff?
- Is the plan stale relative to the spec and current working tree?
- What context does an implementation, review, or architecture-audit worker need now, and what evidence supports including each item?

Its output is a compact, typed answer with source pointers, hashes, freshness, and any known limitations. It may rank or retrieve candidates, but it never turns a candidate into an unqualified fact without checking its authoritative source.

## What Wisp is

The sections below describe the target product. Current implementation and the next slice are separated in the [README](../README.md) and [MVP brief](05-implementation-handoff-mvp.md).

Wisp is all of the following:

- a Rust library for artifact handling, workspace queries, context compilation, and cache/index management;
- a local CLI with stable JSON input and output, suitable for people, CI, and every coding harness;
- eventually, an MCP server that maps tools and resources onto that same library API;
- a local project index that is entirely rebuildable from canonical inputs;
- a bridge between durable planning artifacts and live code evidence.

## What Wisp is not

Wisp must not become any of the following:

- **An agent runtime.** It does not choose arbitrary tools, run an autonomous loop, or replace Claude Agent Teams, Codex multi-agent collaboration, or a harness's approval model.
- **A code parser or code-search engine.** Monokl owns AST parsing, structural search, symbols, reference resolution, and code-fact caching.
- **A second source of truth.** `.wisp/` has no canonical project decision that cannot be reconstructed from Git-tracked artifacts and repository state.
- **A vector database presented as memory.** Semantic retrieval is optional and produces leads, not facts. It is not required for a useful initial product.
- **A replacement for portable artifacts.** Specs, plans, and architecture models remain versioned JSON that any harness can consume without Wisp.
- **A generic workflow engine.** Wisp can report workflow state and validate transitions, but plugins/harnesses retain orchestration and judgment.

## Actors and responsibilities

| Actor | Responsibility | Does not own |
| --- | --- | --- |
| Human | Approves scope, resolves material conflicts, owns external authority | Cache correctness by hand |
| Agent plugin/skill | Performs a cognitive stage and produces/consumes schema artifacts | Durable indexing policy |
| Wisp | Validates artifacts, resolves provenance, compiles context, reports freshness | Code parsing or final semantic judgment |
| Monokl | Supplies current structural code evidence with a declared precision level | Specs, plans, decisions, agent orchestration |
| Git | Stores reviewed canonical history and current worktree state | Semantic relevance |
| Michi | Renders compact agent-facing results | Domain storage or business rules |

## Source-of-truth hierarchy

Wisp classifies inputs explicitly. A response must identify the class of every claim it makes.

| Class | Examples | Authority | Storage |
| --- | --- | --- | --- |
| Canonical authored artifact | `spec@1`, `plan@1`, ADR, architecture model | The tracked file at the resolved Git/worktree state | `docs/` and other configured tracked locations |
| Canonical code/Git evidence | source file, test, commit, diff, branch | The repository state inspected for the request | worktree / Git object database |
| Derived structural evidence | symbol declaration, reference edge, import relationship | Monokl result, including precision/provenance | Monokl cache; recomputable |
| Derived Wisp relationship | spec-to-plan link, artifact status, impact edge | Recomputed from canonical/derived inputs | `.wisp/` SQLite/index |
| Retrieval candidate | FTS or vector match | Never proof by itself | `.wisp/` local index |
| Presentation | TOON/KV/summary | Never authoritative | response only |

## Portable artifact convention

The initial plugin ecosystem uses the following recommended workspace layout:

```text
docs/
  specs/<id>.json                 # gated spec@1
  projects/<linked_spec>.json     # reviewed plan@1
  architecture/model.json         # workspace arch-model@1
.wisp/
  cache/                          # untracked, rebuildable
  state.sqlite                    # untracked, rebuildable derived graph
```

Wisp must make locations configurable because not every repository will have these conventions. Configuration changes must be part of the workspace fingerprint, so an index built with one layout is never silently reused under another.

Artifact files are the interoperable baseline. A Codex, Claude, OpenCode, or other-harness plugin can read a schema-valid artifact directly when Wisp is unavailable. Wisp is the preferred interface because it makes links, hashes, freshness, and relevant context reliable.

## Context is compiled, not remembered

The first integration checks a selected plan/spec handoff without code intelligence, indexing, or a cache. A packet is a source-backed projection, not approval or a substitute for current-code inspection. Known inconsistencies block the proposed pilot; missing optional evidence remains an explicit gap. Neither a committed file nor a passing shape check proves that work was approved.

Agent memory and transcripts are non-authoritative. When artifacts conflict, Wisp reports their identities, hashes, and disagreement; the caller routes spec correction, plan amendment, or architectural review. Wisp does not pick the newest artifact as the winner or alter a governing document itself.

The desired result is not "put all knowledge into context." It is:

1. identify the requested stage and its input artifact(s);
2. verify their identity, links, and freshness;
3. collect only the code, Git, architecture, and documentation evidence needed by that stage;
4. reduce results to a bounded packet with stable pointers and an explicit truncation record;
5. allow the agent to request deeper evidence on demand.

For example, an implementation briefing contains the approved plan and source spec, criteria attached to the requested task, only the affected symbols and tests, applicable architecture invariants, and the current worktree delta. It does not include every prior plan or every file that vaguely resembles the task.

## Trust and safety model

Repository contents are evidence, not instructions. Wisp must preserve this distinction in its API and output labels. In particular, README text, comments, string literals, and copied issue text must never be treated as instructions that alter Wisp's own policy.

Mutations require an explicit operation. Read/query operations must not alter canonical artifacts, Git state, or cache correctness. A persistence command must report whether it merely validated, wrote an uncommitted artifact, or fully committed the artifact. It must never report `persisted` after only writing a local cache entry.

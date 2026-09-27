# Wisp

- **Status:** early implementation in the working tree; release readiness has not been established.
- **Purpose:** local-first project intelligence for coding agents and humans.

Wisp makes a repository's durable project knowledge usable without relying on a conversation's context window. It joins four kinds of evidence:

1. canonical, Git-tracked work artifacts such as specifications, plans, architecture models, and decisions;
2. current repository and historical evidence from Git;
3. structural code evidence supplied by [Monokl](../monokl/README.md); and
4. an explicitly rebuildable local index and briefing cache.

Wisp is not an agent runtime, a replacement for Git, a code parser, or an opaque "AI memory" product. It is a library with a CLI first and an MCP server as a thin later surface. Its job is to answer evidence-backed project questions and prepare a small, relevant context package for a particular stage of work.

## The central rule

The cache is never the authority.

```text
Git-tracked artifacts + Git state + Monokl code evidence
                         │
                         ▼
               Wisp's rebuildable index/cache
                         │
                         ▼
             CLI / MCP evidence-backed response
```

If `.wisp/` is deleted, Wisp must be able to reconstruct it from the workspace. If Wisp is absent, a harness must still be able to read the documented JSON artifacts directly and carry out the portable baseline workflow.

## Repository reading order

Start with [Implementation handoff MVP](docs/05-implementation-handoff-mvp.md) for the next bounded slice, its failure cases, and the evidence required before expanding it. This is a planning draft, not a gated specification or plan.

1. [Vision and boundaries](docs/01-vision-and-boundaries.md)
2. [Architecture and contracts](docs/02-architecture-and-contracts.md)
3. [Delivery plan and acceptance gates](docs/03-delivery-plan.md)
4. [Decision log and open questions](docs/04-decisions-and-open-questions.md)

## Available in the working tree

The CLI implements these spec-only commands; they are not a claim that the acceptance gates have passed:

The foundation source and schema registry are currently uncommitted local work. A fresh checkout of this documentation alone cannot run these commands; land and verify the foundation separately before relying on them.

```bash
cargo run -p wisp-cli -- artifact validate fixtures/spec-valid.json
cargo run -p wisp-cli -- artifact persist candidate.json --workspace .
cargo run -p wisp-cli -- artifact get WISP-001 --workspace .
cargo run -p wisp-cli -- artifact status WISP-001 --workspace .
```

`persist` writes a canonical spec but does not commit it. The schema library embeds five pinned artifact contracts, and the artifact library has read-only discovery and one-hop context assembly. Task-specific preflight, bounded implementation packets, code evidence, SQLite, MCP, and service mode remain planned.

## The next integration (proposed)

```text
Claude / Codex / OpenCode / a human
              │
              ▼
      wisp brief implement --workspace . --plan docs/projects/SPEC-001.json --batch B1
              │
              ▼
  checked plan/spec relationship + exact selected tasks/criteria
  + source digests + explicit gaps
```

This command is proposed, not implemented. The first integration is read-only and cache-free. It does not run tests, choose batches, grant approval, or query Monokl. Smith inspects current code and performs implementation and verification. MCP and compact rendering follow only after the CLI handoff proves useful.

## Related projects

- **Monokl** supplies AST-aware code evidence, code search, symbols, definitions, references, and precision metadata. Wisp must not duplicate its parser, AST cache, or code index.
- **Michi** is a future optional presentation adapter. The MVP has no Michi dependency; proposed decision D-029 narrows its release gate to features that use it.
- **Callisto** offers precedents for authorized effects, typed observations, receipts, and crash-safe writes. Its current Git access uses subprocesses; no standalone `callisto-vcs` dependency is assumed. Check API and license compatibility before code reuse.
- **Lumen** observes agent sessions, cache use, and retrieval loops. It is an evaluation/telemetry companion, never project truth.
- **Prism** evaluates whether Wisp context actually improves task success, correctness, latency, and cost across harnesses.

See [Architecture and contracts](docs/02-architecture-and-contracts.md) for the precise boundaries.

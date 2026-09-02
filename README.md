# Wisp

- **Status:** design repository; no implementation has begun.
- **Purpose:** local-first project intelligence for coding agents and humans.

Wisp makes a repository's durable project knowledge usable without relying on a
conversation's context window. It joins four kinds of evidence:

1. canonical, Git-tracked work artifacts such as specifications, plans,
   architecture models, and decisions;
2. current repository and historical evidence from Git;
3. structural code evidence supplied by [Monokl](../monokl/README.md); and
4. an explicitly rebuildable local index and briefing cache.

Wisp is not an agent runtime, a replacement for Git, a code parser, or an
opaque "AI memory" product. It is a library with a CLI first and an MCP server
as a thin later surface. Its job is to answer evidence-backed project questions
and prepare a small, relevant context package for a particular stage of work.

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

If `.wisp/` is deleted, Wisp must be able to reconstruct it from the workspace.
If Wisp is absent, a harness must still be able to read the documented JSON
artifacts directly and carry out the portable baseline workflow.

## Repository reading order

1. [Vision and boundaries](docs/01-vision-and-boundaries.md)
2. [Architecture and contracts](docs/02-architecture-and-contracts.md)
3. [Delivery plan and acceptance gates](docs/03-delivery-plan.md)
4. [Decision log and open questions](docs/04-decisions-and-open-questions.md)

## The intended user experience

```text
Claude / Codex / OpenCode / a human
              │
              ▼
      wisp brief implement --plan PLAN-014
              │
              ▼
  small, cited package: plan + spec + relevant invariants
  + affected symbols/tests + current Git delta + next actions
```

The same capability will eventually be exposed as an MCP tool such as
`wisp_brief`. The CLI JSON result is the primary contract; TOON/KV rendering is
an optimized presentation, not a storage or mutation format.

## Related projects

- **Monokl** supplies AST-aware code evidence, code search, symbols,
  definitions, references, and precision metadata. Wisp must not duplicate its
  parser, AST cache, or code index.
- **Michi** supplies token-efficient agent output (TOON, KV, hints, MCP result
  assembly, truncation) through a local path integration during coordinated
  development. Wisp will not be published until it can depend on a compatible,
  versioned Michi release.
- **Callisto** offers useful precedents and potentially reusable permissively
  licensed pieces for `gix`-backed VCS access and crash-safe writes. License
  compatibility must be checked before code reuse.
- **Lumen** observes agent sessions, cache use, and retrieval loops. It is an
  evaluation/telemetry companion, never project truth.
- **Prism** evaluates whether Wisp context actually improves task success,
  correctness, latency, and cost across harnesses.

See [Architecture and contracts](docs/02-architecture-and-contracts.md) for
the precise boundaries.

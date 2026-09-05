# Decisions and defects

Open items against the JSON spec and plan, found in review and not yet corrected there. Tracked here until each is fixed or explicitly accepted.

## Status

| Item | Type | Status | Fix |
| --- | --- | --- | --- |
| Criteria misattribution | Plan defect | Unresolved | T1 claims `["AC-001"]` only |
| `wisp artifact status` scope creep | Plan defect | Shipped, uncovered by any criterion | Add an acceptance criterion for it retroactively |
| Scope beyond non-goals | Plan defect | Shipped without a spec or gate | Reconcile under a new gated spec, or hold at `spec@1`-only until WISP-001 closes |
| Binding gates never run | Gate | Outstanding | Run `scribe:exit-gate` on the spec and `navigator:challenger` on the plan |

## Unresolved plan defects

**Criteria misattribution.** Task T1 in `docs/projects/WISP-001.json` claims `covers_criteria: ["AC-001", "AC-005", "AC-007"]`, but T1 only defines types — persistence (`AC-005`) and retrieval (`AC-007`) are proven by T3 and T4, which also both claim them. Three tasks claiming one criterion hides which commit is the real proof.

**`wisp status` / `wisp artifact status` scope creep.** Shipped as `wisp artifact status`, but no acceptance criterion in `docs/specs/WISP-001.json` and no `done_when` item in `docs/requirements/REQ-WISP-001.json` covers it. It is already built and tested, so the criterion is added retroactively.

**Scope beyond non-goals.** `wisp-artifacts` ships `discover_graph`/`assemble_context` (multi-artifact-type discovery, link resolution, one-hop context assembly), and `wisp-schema` embeds schemas for four artifact types beyond `spec@1`. WISP-001's non-goals exclude other artifact types and impact/context work — that is M3 in [`../../03-delivery-plan.md`](../../03-delivery-plan.md).

## Implicit decisions worth making explicit

**Schema registry: vendor + pin.** `AC-002` pins `schemas/spec@1.json` to `agent-plugins` revision `b5e2db19cfd2358fe9dcecfce019eab936817e23`, vendored with provenance in `schemas/PROVENANCE.md`. This was option 3 under Q-001 in [`../../04-decisions-and-open-questions.md`](../../04-decisions-and-open-questions.md), which has since closed Q-001 as **D-010** — schemas vendored from Wisp Plugins at a pinned revision; `wisp-contracts` carries vocabulary types only — and set the re-pin process there: a deliberate bump of the recorded revision and checksums, with persisted artifacts not revalidated on re-pin. Still open for this repo: who decides a re-pin, and how the vendored checksum updates when they do.

## Gate status

No `verdict@1` exists anywhere in the repo. Per [`../../../PRINCIPLES.md`](../../../PRINCIPLES.md), `scribe:exit-gate` on the spec and `navigator:challenger` on the plan are binding before implementation, not optional. Both are outstanding, and the defects above are exactly what `navigator:challenger` checks for.

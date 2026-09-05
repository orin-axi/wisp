# wisp-schema

Vendored, version-pinned JSON Schema loading and validation.

## Overview

Embeds JSON Schemas at compile time and validates with a draft 2020-12 validator. Never reads a schema from a mutable sibling checkout. Five contracts are embedded — `requirement@1`, `research-report@1`, `spec@1`, `plan@1`, `arch-model@1` — which is more than WISP-001 asked for; see [`../../ARCHITECTURE.md`](../../ARCHITECTURE.md#ahead-of-spec).

- `Contract` — the five embedded contracts, their schema IDs, and canonical directories.
- `validate_contract` — validate a parsed document against a selected contract.
- `validate_spec_json` / `validate_spec_value` — parse and/or validate a `spec@1` candidate, returning `ValidatedSpec { id, value }` or a typed `SpecValidationError` (invalid JSON with a source span, schema violation, unsafe ID).

Depends on `wisp-model` only.

## Status

Shipping for `spec@1`: validation, error types, and unit tests. `Contract`'s other four schemas are embedded but have no dedicated validation entry point — only `validate_contract` reaches them, used today by `wisp-artifacts`'s graph discovery.

## License

`FSL-1.1-MIT` — the Wisp suite license (D-021). Converts to MIT two years after each release.

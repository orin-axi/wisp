# wisp-cli

The `wisp` binary: a thin JSON-in/JSON-out boundary over `wisp-artifacts` and `wisp-schema`. No domain logic lives here.

## Overview

```bash
wisp artifact validate <candidate.json|->
wisp artifact persist <candidate.json|-> --workspace <path>
wisp artifact get <id> --workspace <path>
wisp artifact status <id> --workspace <path>
```

Every command emits one deterministic JSON object on stdout and a nonzero exit on failure. `--format human` renders a `miette` diagnostic on stderr instead, for interactive use.

Depends on `wisp-model`, `wisp-schema`, and `wisp-artifacts`.

## Status

Shipping, with integration tests in `tests/cli.rs` covering validate/persist/get/status across both success and error paths.

## License

`FSL-1.1-MIT` — the Wisp suite license (D-021). Converts to MIT two years after each release.

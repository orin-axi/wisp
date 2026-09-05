# wisp-fixtures

Reserved for shared fixture data and black-box test helpers used across the workspace's test suites.

## Overview

Nothing yet beyond a `FIXTURE_STAGE` marker constant. The fixture JSON files WISP-001 needs — `fixtures/spec-valid.json`, `fixtures/spec-malformed.json`, `fixtures/spec-unknown-property.json`, `fixtures/spec-missing-required.json` — live under the top-level `fixtures/` directory and are read directly by `wisp-cli`'s tests. Move them here if a second consumer needs them, rather than duplicating.

Depends on `wisp-model` only.

## Status

Stub. No fixtures, no helpers, no tests.

## License

`FSL-1.1-MIT` — the Wisp suite license (D-021). Converts to MIT two years after each release.

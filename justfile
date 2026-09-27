default: ci

docs-lint:
    scripts/docs-lint.sh

ci: docs-lint

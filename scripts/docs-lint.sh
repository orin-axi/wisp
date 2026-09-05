#!/usr/bin/env bash
# Lint the repository's markdown against the house style: no filler words, balanced
# code fences, every D-/Q- reference defined in the decision log, no stale names.
# Read-only. Exit 1 on any finding so `just ci-fast` can gate on it.
set -euo pipefail
cd "$(dirname "$0")/.."

files=$(git ls-files --cached --others --exclude-standard -- '*.md' | grep -v -E '^(target|node_modules|docs/research|docs/projects|docs/specs|docs/requirements)/')
status=0

echo "== filler words =="
if rg -n -i '\b(leverage|delve|robust|seamless|crucially|worth noting|in order to|comprehensive|cutting-edge|empower|streamline|holistic|synerg|genuinely|materially)\b' $files | grep -v -i -E 'OCI|verbatim|quot'; then status=1; else echo none; fi

echo "== emoji =="
if rg -n -P '[\x{1F300}-\x{1FAFF}]' $files | grep -v 'local 🧠'; then status=1; else echo none; fi

echo "== unbalanced code fences =="
odd=0
for f in $files; do
  n=$(grep -c '^```' "$f" || true)
  if [ $((n % 2)) -ne 0 ]; then echo "$f"; odd=1; fi
done
[ "$odd" -eq 0 ] && echo none || status=1

echo "== D-/Q- references without a definition =="
log=docs/04-decisions-and-open-questions.md
rg -o -I -N 'D-0[0-9]{2}|Q-0[0-9]{2}' $files | sort -u > /tmp/wisp-docs-lint-refs
rg -o -I -N '^### (D|Q)-0[0-9]{2}' "$log" | rg -o '(D|Q)-0[0-9]{2}' | sort -u > /tmp/wisp-docs-lint-defs
# Questions closed by a decision are referenced but have no heading; list them here.
resolved='Q-001 Q-002 Q-003 Q-004 Q-005 Q-006 Q-010 Q-014 Q-015'
missing=$(comm -23 /tmp/wisp-docs-lint-refs /tmp/wisp-docs-lint-defs | grep -v -x -F -f <(printf '%s\n' $resolved) || true)
if [ -n "$missing" ]; then echo "$missing"; status=1; else echo none; fi

echo "== stale names =="
if rg -n -i 'orin[-_]contracts|state\.sqlite|\.wisp/config\.toml|wisp_impact\b|wisp_status\b|wisp_verify\b|CLI adapter phase' $files | grep -v -i -E 'no CLI|\bnot\b|never|was |formerly|earlier draft'; then status=1; else echo none; fi

exit $status

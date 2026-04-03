#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
FISH_RUNNER="$SCRIPT_DIR/run_caseforge_test_queries.fish"

if ! command -v fish >/dev/null 2>&1; then
  echo "Error: fish is required for this wrapper because the canonical runner is run_caseforge_test_queries.fish" >&2
  exit 1
fi

exec fish "$FISH_RUNNER" "$@"

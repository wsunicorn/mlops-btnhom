#!/usr/bin/env bash
set -e

# Backward-compatible alias for list_model.sh used in README.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
"$SCRIPT_DIR/list_model.sh" "$@"

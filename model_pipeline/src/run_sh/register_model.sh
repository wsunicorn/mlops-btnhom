#!/usr/bin/env bash
set -e

# Backward-compatible alias for register.sh used in README.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
"$SCRIPT_DIR/register.sh" "$@"

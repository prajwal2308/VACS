#!/usr/bin/env bash
# Point this repo's git hooks at githooks/ (strips Cursor co-author trailers).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
git -C "$ROOT" config core.hooksPath githooks
chmod +x "$ROOT/githooks/prepare-commit-msg"
echo "Installed githooks → $ROOT/githooks"

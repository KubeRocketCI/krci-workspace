#!/usr/bin/env bash
# Run `git pull --ff-only` in every component repo under sources/.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCES_DIR="${SCRIPT_DIR}/sources"

if [ ! -d "$SOURCES_DIR" ]; then
    echo "No sources/ directory yet. Run ./bootstrap.sh first."
    exit 1
fi

for dir in "$SOURCES_DIR"/*/; do
    name="$(basename "${dir%/}")"
    if [ ! -d "${dir}/.git" ]; then
        echo "⏭️  Skipping ${name} (not a git repo)"
        continue
    fi

    echo "🔄 Pulling ${name}..."
    if git -C "${dir}" pull --ff-only; then
        echo "✅ ${name} done"
    else
        echo "❌ ${name} failed"
    fi
    echo
done

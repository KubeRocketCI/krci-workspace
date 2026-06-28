#!/usr/bin/env bash
#
# bootstrap.sh - Assemble a KubeRocketCI development workspace.
#
# Reads repos.yaml (the manifest) and clones each component repository into
# the sources/ directory as an INDEPENDENT git repo (its own .git, own remote).
# No submodules, no pinned pointers — every clone is fully writable and you
# branch / commit / PR per component with zero parent-repo overhead.
#
# Usage:
#   ./bootstrap.sh                      # clone every repo into sources/
#   ./bootstrap.sh krci-portal edp-tekton   # clone only the named repos
#   ./bootstrap.sh --group ci           # clone every repo in a manifest group
#   ./bootstrap.sh --list               # list manifest entries, clone nothing
#
# Existing directories are skipped (safe to re-run). Zero dependencies beyond
# git + awk.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFEST="${SCRIPT_DIR}/repos.yaml"
SOURCES_DIR="${SCRIPT_DIR}/sources"

if [[ ! -f "$MANIFEST" ]]; then
  echo "Error: manifest not found at $MANIFEST" >&2
  exit 1
fi

# Emit "dir<TAB>url<TAB>group<TAB>desc" for every entry in repos.yaml.
parse_manifest() {
  awk '
    /^[[:space:]]*#/  { next }
    /^[[:space:]]*-[[:space:]]*dir:/ {
      if (dir != "") print dir "\t" url "\t" group "\t" desc
      dir=""; url=""; group=""; desc=""
    }
    {
      line=$0
      sub(/^[[:space:]]*-?[[:space:]]*/, "", line)
      split(line, kv, ":")
      key=kv[1]
      val=line; sub(/^[^:]*:[[:space:]]*/, "", val)
      gsub(/^"|"$/, "", val)
      if (key=="dir")   dir=val
      if (key=="url")   url=val
      if (key=="group") group=val
      if (key=="desc")  desc=val
    }
    END { if (dir != "") print dir "\t" url "\t" group "\t" desc }
  ' "$MANIFEST"
}

ALL_ENTRIES="$(parse_manifest)"

list_manifest() {
  printf "%-26s %-9s %s\n" "DIR" "GROUP" "DESCRIPTION"
  while IFS=$'\t' read -r dir url group desc; do
    [[ -z "$dir" ]] && continue
    printf "%-26s %-9s %s\n" "$dir" "$group" "$desc"
  done <<< "$ALL_ENTRIES"
}

# --- argument handling --------------------------------------------------------
SELECTED=""        # newline-separated dir names to clone
FILTER_GROUP=""

case "${1:-}" in
  --list|-l)
    list_manifest
    exit 0
    ;;
  --group|-g)
    FILTER_GROUP="${2:-}"
    if [[ -z "$FILTER_GROUP" ]]; then echo "Error: --group requires a value" >&2; exit 1; fi
    ;;
  --help|-h)
    grep '^#' "$0" | sed 's/^# \{0,1\}//'
    exit 0
    ;;
esac

if [[ -n "$FILTER_GROUP" ]]; then
  while IFS=$'\t' read -r dir url group desc; do
    [[ "$group" == "$FILTER_GROUP" ]] && SELECTED+="$dir"$'\n'
  done <<< "$ALL_ENTRIES"
  if [[ -z "$SELECTED" ]]; then echo "Error: no repos in group '$FILTER_GROUP'" >&2; exit 1; fi
elif [[ $# -gt 0 ]]; then
  for want in "$@"; do
    if ! grep -qP "^${want}\t" <<< "$ALL_ENTRIES"; then
      echo "Error: '$want' is not in the manifest. Run './bootstrap.sh --list'." >&2
      exit 1
    fi
    SELECTED+="$want"$'\n'
  done
else
  SELECTED="$(cut -f1 <<< "$ALL_ENTRIES")"
fi

# --- clone --------------------------------------------------------------------
url_for() { grep -P "^${1}\t" <<< "$ALL_ENTRIES" | cut -f2; }

mkdir -p "$SOURCES_DIR"
echo "Workspace: $SCRIPT_DIR"
echo "Sources:   $SOURCES_DIR"
echo ""

FAILED=""
FAIL_COUNT=0
TOTAL=0
while IFS= read -r dir; do
  [[ -z "$dir" ]] && continue
  TOTAL=$((TOTAL + 1))
  if [[ -d "${SOURCES_DIR}/${dir}/.git" ]]; then
    echo "✔ sources/$dir (already present, skipped)"
    continue
  fi
  url="$(url_for "$dir")"
  echo "⬇ cloning $dir -> sources/$dir ..."
  if git clone "$url" "${SOURCES_DIR}/${dir}"; then
    echo "  done."
  else
    echo "  FAILED: $dir"
    FAILED="$FAILED $dir"
    FAIL_COUNT=$((FAIL_COUNT + 1))
  fi
  echo ""
done <<< "$SELECTED"

echo "=== Workspace ready: $SCRIPT_DIR ==="
echo "Processed $((TOTAL - FAIL_COUNT))/$TOTAL repositories."
if [[ $FAIL_COUNT -gt 0 ]]; then
  echo "Failed:$FAILED" >&2
  exit 1
fi

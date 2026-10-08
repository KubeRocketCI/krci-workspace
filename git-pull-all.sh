#!/usr/bin/env bash
# Fetch --prune, then fast-forward, every component repo under sources/, in parallel.
# JOBS: parallel workers, default 4.
# Fetch: 3 attempts per repo, never prompts, SSH connect capped at 15s, stalled session at 30s.
# SSH: one multiplexed connection per host, closed on exit.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCES_DIR="${SCRIPT_DIR}/sources"
JOBS="${JOBS:-4}"

if [ ! -d "$SOURCES_DIR" ]; then
    echo "No sources/ directory yet. Run ./bootstrap.sh first."
    exit 1
fi

OUT_DIR="$(mktemp -d)"
SSH_DIR="$(mktemp -d /tmp/krci-pull.XXXXXX)"
export OUT_DIR

cleanup() {
    local sock
    for sock in "$SSH_DIR"/*; do
        [ -S "$sock" ] && ssh -O exit -o ControlPath="$sock" _ >/dev/null 2>&1
    done
    rm -rf "$OUT_DIR" "$SSH_DIR"
}
trap cleanup EXIT

export GIT_TERMINAL_PROMPT=0
export GIT_SSH_COMMAND="${GIT_SSH_COMMAND:-ssh} -o BatchMode=yes -o ConnectTimeout=15 -o ServerAliveInterval=10 -o ServerAliveCountMax=3 -o ControlMaster=auto -o ControlPath=${SSH_DIR}/%C -o ControlPersist=30"

fetch_retry() {
    local dir="$1" attempt out
    for attempt in 1 2 3; do
        if out="$(git -C "$dir" fetch --prune </dev/null 2>&1)"; then
            [ -n "$out" ] && printf '%s\n' "$out"
            return 0
        fi
        [ "$attempt" -lt 3 ] && sleep "$attempt"
    done
    printf '%s\n' "$out"
    return 1
}

show_progress() {
    [ -t 2 ] || return 0
    local finished width=20 filled
    finished="$(find "$OUT_DIR" -name '*.done' | wc -l | tr -d ' ')"
    filled=$((finished * width / TOTAL))
    printf '\r[%s%s] %d/%d' \
        "$(printf '%*s' "$filled" '' | tr ' ' '#')" \
        "$(printf '%*s' $((width - filled)) '' | tr ' ' '-')" \
        "$finished" "$TOTAL" >&2
}

pull_repo() {
    local dir="$1" name
    name="$(basename "$dir")"
    {
        echo "== ${name}"
        if fetch_retry "$dir" && git -C "$dir" merge --ff-only '@{u}' </dev/null 2>&1; then
            echo "OK: ${name}"
        else
            echo "FAILED: ${name}"
            touch "${OUT_DIR}/${name}.failed"
        fi
        echo
    } >"${OUT_DIR}/${name}.log" 2>&1
    touch "${OUT_DIR}/${name}.done"
    show_progress
}
export -f fetch_retry show_progress pull_repo

repos=()
for dir in "$SOURCES_DIR"/*/; do
    dir="${dir%/}"
    if [ ! -e "${dir}/.git" ]; then
        echo "SKIPPED: $(basename "$dir") (not a git repo)"
        continue
    fi
    repos+=("$dir")
done

if [ "${#repos[@]}" -eq 0 ]; then
    echo "No git repos in ${SOURCES_DIR}."
    exit 0
fi

TOTAL="${#repos[@]}"
export TOTAL

# First repo runs alone so it opens the SSH master the parallel workers reuse.
pull_repo "${repos[0]}"
if [ "$TOTAL" -gt 1 ]; then
    printf '%s\0' "${repos[@]:1}" | xargs -0 -n1 -P "$JOBS" bash -c 'pull_repo "$0"'
fi
[ -t 2 ] && printf '\r\033[K' >&2

cat "$OUT_DIR"/*.log

failed=("$OUT_DIR"/*.failed)
if [ -e "${failed[0]}" ]; then
    echo "Failed ${#failed[@]}/${#repos[@]}: $(for f in "${failed[@]}"; do basename "$f" .failed; done | paste -sd ' ' -)"
    exit 1
fi
echo "Synced ${#repos[@]}/${#repos[@]}"

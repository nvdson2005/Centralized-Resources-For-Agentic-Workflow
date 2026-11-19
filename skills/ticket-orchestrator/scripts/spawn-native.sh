#!/usr/bin/env bash
# Start one worker as a Claude Code background session in its worktree.
# Prints: id=<bg id> name=<name> state=<ready|blocked|missing>
# Usage: spawn-native.sh --name t-<ticket> --cwd <worktree> --model <model> --effort <level>
#                        --mode <permission mode, must equal the coordinator's> --brief <brief.md>
set -euo pipefail

name="" cwd="" model="sonnet" effort="medium" mode="" brief=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --name) name="$2"; shift 2 ;;
    --cwd) cwd="$2"; shift 2 ;;
    --model) model="$2"; shift 2 ;;
    --effort) effort="$2"; shift 2 ;;
    --mode) mode="$2"; shift 2 ;;
    --brief) brief="$2"; shift 2 ;;
    *) echo "unknown arg: $1" >&2; exit 64 ;;
  esac
done
for v in name cwd mode brief; do
  [[ -n "${!v}" ]] || { echo "--$v is required" >&2; exit 64; }
done
[[ -d "$cwd" ]] || { echo "cwd not found: $cwd" >&2; exit 66; }
[[ -f "$brief" ]] || { echo "brief not found: $brief" >&2; exit 66; }

out="$(cd "$cwd" && claude --bg --model "$model" --effort "$effort" -n "$name" \
        --permission-mode "$mode" "$(cat "$brief")" 2>&1)"
# First line looks like: "backgrounded · d7ef8bea · t-123"
id="$(printf '%s\n' "$out" | sed -n '1s/^backgrounded · \([^ ]*\) · .*/\1/p')"
if [[ -z "$id" ]]; then
  echo "spawn failed:" >&2
  printf '%s\n' "$out" >&2
  exit 1
fi

state="$(bash "$(dirname "$0")/wait-ready.sh" --name "$name" || true)"
echo "id=$id name=$name state=$state"

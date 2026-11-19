#!/usr/bin/env bash
# Wait until a named Claude session registers, then report its state.
# Prints one word: ready | blocked | missing.  Exit 0 ready, 2 blocked, 1 missing.
# Usage: wait-ready.sh --name <session-name> [--timeout <seconds, default 60>]
set -euo pipefail

name="" timeout=60
while [[ $# -gt 0 ]]; do
  case "$1" in
    --name) name="$2"; shift 2 ;;
    --timeout) timeout="$2"; shift 2 ;;
    *) echo "unknown arg: $1" >&2; exit 64 ;;
  esac
done
[[ -n "$name" ]] || { echo "--name is required" >&2; exit 64; }

state_of() {
  claude agents --json 2>/dev/null | python3 -c '
import json, sys
name = sys.argv[1]
try:
    rows = json.load(sys.stdin)
except Exception:
    print("missing"); sys.exit()
for r in rows:
    if r.get("name") == name:
        # background rows carry "state", interactive rows carry "status"
        s = (r.get("state") or r.get("status") or "").lower()
        print("blocked" if s == "blocked" else "ready")
        break
else:
    print("missing")
' "$name"
}

deadline=$((SECONDS + timeout))
last="missing"
while (( SECONDS < deadline )); do
  last="$(state_of)"
  [[ "$last" == "missing" ]] || break
  sleep 2
done

# A fresh session can flip to blocked a few seconds after registering (dialog, permission prompt).
if [[ "$last" == "ready" ]]; then
  sleep 5
  last="$(state_of)"
fi

echo "$last"
case "$last" in ready) exit 0 ;; blocked) exit 2 ;; *) exit 1 ;; esac

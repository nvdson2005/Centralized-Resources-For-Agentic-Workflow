#!/usr/bin/env bash
# Start one worker as an interactive Claude session in its own tmux window, then paste the brief.
# Exit 0 = brief sent, 3 = a dialog is on screen (user must answer it, then re-run with --paste-only),
# 1 = session never registered.
# Usage: spawn-tmux.sh --session orch-<run-id> --name t-<ticket> --cwd <worktree> --model <model>
#                      --effort <level> --mode <permission mode, must equal the coordinator's>
#                      --brief <brief.md> [--paste-only]
set -euo pipefail

session="" name="" cwd="" model="sonnet" effort="medium" mode="" brief="" paste_only=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --session) session="$2"; shift 2 ;;
    --name) name="$2"; shift 2 ;;
    --cwd) cwd="$2"; shift 2 ;;
    --model) model="$2"; shift 2 ;;
    --effort) effort="$2"; shift 2 ;;
    --mode) mode="$2"; shift 2 ;;
    --brief) brief="$2"; shift 2 ;;
    --paste-only) paste_only=1; shift ;;
    *) echo "unknown arg: $1" >&2; exit 64 ;;
  esac
done
for v in session name brief; do
  [[ -n "${!v}" ]] || { echo "--$v is required" >&2; exit 64; }
done
[[ -f "$brief" ]] || { echo "brief not found: $brief" >&2; exit 66; }
target="$session:$name"
here="$(dirname "$0")"

if (( ! paste_only )); then
  for v in cwd mode; do
    [[ -n "${!v}" ]] || { echo "--$v is required" >&2; exit 64; }
  done
  [[ -d "$cwd" ]] || { echo "cwd not found: $cwd" >&2; exit 66; }
  cmd="claude --model '$model' --effort '$effort' -n '$name' --permission-mode '$mode'"
  if tmux has-session -t "$session" 2>/dev/null; then
    tmux new-window -d -t "$session" -n "$name" -c "$cwd" "$cmd"
  else
    tmux new-session -d -s "$session" -n "$name" -x 220 -y 50 -c "$cwd" "$cmd"
  fi
fi

dialog_on_screen() {
  # Trust and permission dialogs all end with this footer; the prompt glyph alone is NOT a signal.
  tmux capture-pane -p -t "$target" | grep -q 'Enter to confirm'
}

# Wait for the session to register with Claude (not for a glyph on screen).
for _ in $(seq 1 45); do
  if dialog_on_screen; then echo "dialog"; exit 3; fi
  state="$(bash "$here/wait-ready.sh" --name "$name" --timeout 2 2>/dev/null || true)"
  [[ "$state" == "missing" ]] || break
done
if dialog_on_screen; then echo "dialog"; exit 3; fi
[[ "${state:-missing}" != "missing" ]] || { echo "missing"; exit 1; }

# Bracketed paste keeps a multi-line brief as one prompt.
buf="orch-$name"
tmux load-buffer -b "$buf" "$brief"
tmux paste-buffer -p -d -b "$buf" -t "$target"
sleep 1
tmux send-keys -t "$target" Enter
echo "sent target=$target"

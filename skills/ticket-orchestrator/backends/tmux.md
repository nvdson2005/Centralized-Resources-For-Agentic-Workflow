# Backend: tmux (tmux hosting + cross-session messages)

Workers are interactive Claude sessions, one tmux window each in session `orch-<run-id>`, so the user can watch all of them in one terminal (`tmux attach -t orch-<run-id>`). tmux only does hosting. Messaging is the same as **native**: tmux-hosted sessions show up in `ListAgents` like any other local session.

Read `native.md` for: requirements (same permission mode!), brief placeholders, reply/send, stall watch, event mapping. Use them unchanged. This file lists only what differs.

## Verbs that differ from native

| Verb | How |
|---|---|
| spawn | `bash <skill>/scripts/spawn-tmux.sh --session orch-<run-id> --name t-<ticket> --cwd <worktree> --model <model> --effort <effort> --mode <permission_mode> --brief <brief>` |
| ready check | Built into `spawn-tmux.sh`: it waits for the session to register, refuses to paste into a dialog, and exits `3` with `dialog` when one is on screen |
| read | `tmux capture-pane -p -t orch-<run-id>:t-<ticket> -S -200` |
| stop | `tmux kill-window -t orch-<run-id>:t-<ticket>` |
| user watches | `tmux attach -t orch-<run-id>`, then `Ctrl-b w` to pick a worker |

## Why messaging doesn't use tmux keystrokes

Driving workers with `send-keys` and scraping `capture-pane` was tested and is fragile: a readiness check that greps for the prompt glyph also matches the trust dialog's selector, and idle detection by matching screen text breaks on invisible characters (non-breaking spaces). Use keystrokes only for the one-time brief paste, after `spawn-tmux.sh` confirmed no dialog is on screen. Replies always go through `SendMessage`.

## Dialog on spawn

`spawn-tmux.sh` exit `3` = a trust or permission dialog is on screen. Tell the user: `tmux attach -t orch-<run-id>`, select window `t-<ticket>`, answer the dialog, detach with `Ctrl-b d`. Then re-run the script with `--paste-only` to send the brief.

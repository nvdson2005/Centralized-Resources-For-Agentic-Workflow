# Backend: native (`claude --bg` hosting + cross-session messages)

Plain Claude Code, no extra app. Workers are background sessions. Messages travel over Claude's local session socket and arrive in the receiver's conversation, mid-turn included.

## Requirements

- Coordinator's own session name: from `ListAgents` ("This session is <name>"). Put it in `{{COORDINATOR}}`.
- **Workers must run in the coordinator's permission mode.** If the modes differ, Claude holds cross-session messages for manual approval, and the run stalls with no signal. Set `permission_mode` in config to the mode the coordinator runs in.
- Worker session name = `t-<ticket>`. Unique per run.

## Brief placeholders

| Placeholder | Value |
|---|---|
| `{{COORDINATOR}}` | `the session named <coordinator name>` |
| `{{ASK}}` | `SendMessage` to `<coordinator name>` with the `[ORCH … QUESTION]` header, then end your turn |
| `{{BLOCKED}}` | `SendMessage` to `<coordinator name>` with the `[ORCH … BLOCKED]` header, then end your turn |
| `{{DONE}}` | `SendMessage` to `<coordinator name>` with the `[ORCH … DONE]` header, then end your turn |
| `{{FAILED}}` | `SendMessage` to `<coordinator name>` with the `[ORCH … FAILED]` header, then end your turn |

## Verbs

| Verb | How |
|---|---|
| spawn | `bash <skill>/scripts/spawn-native.sh --name t-<ticket> --cwd <worktree> --model <model> --effort <effort> --mode <permission_mode> --brief <brief>` (prints the bg session id) |
| ready check | `bash <skill>/scripts/wait-ready.sh --name t-<ticket>` (prints `ready`, `blocked` or `missing`) |
| read | `claude logs <id>` |
| reply / send | `SendMessage` to the `from=` address of the worker's message (or to `t-<ticket>`). A message to an idle worker wakes it |
| stall watch | After each spawn and each reply, `SendMessage` to `t-<ticket>` with `notify_when_idle: true` and no message. An idle notice with no `[ORCH …]` message just before it = STALLED |
| list | `claude agents --json` (filter `name` starting `t-`) |
| stop | `claude stop <id>` |
| ask user (gate) | `AskUserQuestion` in the coordinator |
| user watches | `claude agents` (agent view), `claude attach <id>` for one worker |

## Event mapping

| Signal | Event |
|---|---|
| `<cross-session-message>` starting `[ORCH <t> QUESTION]` | QUESTION |
| `… BLOCKED]` | BLOCKED |
| `… DONE]` / `… FAILED]` | DONE / FAILED |
| idle notice without a preceding `[ORCH …]` message, or `state: blocked` in `claude agents --json` | STALLED |
| session missing from `claude agents --json` | LOST |

## Known traps

- **Startup trust dialogs** ("New MCP server found in this project", "Allow external CLAUDE.md imports") appear the first time Claude opens a new folder. A background worker stuck on one shows `state: blocked` and nothing else. Tell the user to run `claude attach <id>`, answer the dialog once, and detach with ←. The answer persists for that folder.
- A worker that ends its turn without messaging looks idle, not finished. That's why the stall watch exists.

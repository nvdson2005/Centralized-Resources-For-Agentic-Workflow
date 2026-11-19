# Backend: orca (Orca hosting + Orca mail)

Use when the coordinator runs inside Orca (`TERM_PROGRAM=Orca`, `orca status` reachable). Orca injects its own worker preamble (task id, `ask`, `worker_done` commands), so the brief only needs the placeholders below. Before the first command, fetch Orca's version-matched guide once with `orca skills get orchestration` and follow it where it differs from this file.

## Brief placeholders

| Placeholder | Value |
|---|---|
| `{{COORDINATOR}}` | `your Orca coordinator` |
| `{{ASK}}` | `orca orchestration ask --question "<message>"`, then end your turn |
| `{{BLOCKED}}` | `orca orchestration ask --question "<message>"`, then end your turn (a gate is a question the coordinator relays to the user) |
| `{{DONE}}` | the `worker_done` command from your Orca preamble, outcome `succeeded`, message = evidence |
| `{{FAILED}}` | the `worker_done` command from your Orca preamble, outcome `failed`, message = reason + evidence |

## Verbs

| Verb | Command |
|---|---|
| spawn | `orca orchestration worker-start --spec-file <brief> --task-title "<ticket>" --worktree path:<worktree> --agent claude --model <model> --effort <effort> --json` (worktree must belong to a project Orca knows: `orca repo list --json`; otherwise use `--worktree current` and put the path in the brief) |
| ready check | Receipt `state: ready`. Then `orca orchestration worker-show --dispatch <id>`. An `escalation` soon after start = dialog or prompt in the worker tab |
| read | `orca orchestration worker-read --dispatch <id> --source auto` |
| reply | `orca orchestration reply --id <msg_id> --body "<answer>"` |
| send (steer) | `orca orchestration send --to dispatch:<id> --subject "<s>" --body "<b>"` |
| list | `orca orchestration worker-list` and `orca worktree ps` |
| stop | `orca orchestration worker-stop --dispatch <id>` |
| ask user (gate) | `orca orchestration gate-create --task <task_id> --question "<q>" --options '["approve","reject"]'`, plus tell the user in chat. Resolve with `gate-resolve` after they answer |
| user watches | The worker's Orca tab |

## Event mapping

| Orca mail / state | Event |
|---|---|
| `question` mail with `[ORCH … QUESTION]` | QUESTION |
| `question` mail with `[ORCH … BLOCKED]` | BLOCKED |
| `worker_done` outcome succeeded | DONE |
| `worker_done` outcome failed | FAILED |
| `escalation` with `stopReason` | STALLED |
| `exited` / `lost` | LOST |

## Wake behavior

Orca wakes the coordinator only when it is **idle**. Mail that arrives mid-turn waits. So:
- End your turn as soon as you are waiting.
- Before ending any turn, run `orca orchestration check` once and handle whatever is there.
- Lost track: `orca orchestration inbox --terminal run:<run_id> --limit 50`.
- Resume in a new session: `orca orchestration run-use <run_id>`.

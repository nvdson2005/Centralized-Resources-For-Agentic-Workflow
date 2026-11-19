# ticket-orchestrator

A multi-agent setup for working on several tickets at once without jumping between windows.

## The problem

Running one agent session per ticket works well until you have three or four of them. Then most of your time goes to switching windows, scrolling back to see which session is waiting on you, and re-reading context to answer a question you already answered in another window.

## The idea

One **coordinator** session talks to you. It starts one **worker** session per ticket, each in its own worktree. Workers implement. When a worker is unsure about something, it doesn't guess and it doesn't wait for you in a window you aren't watching. It sends the question to the coordinator.

The coordinator checks the question against the project's sources (previous answers in this run, docs, the code index on that worker's worktree, a read-only database). If the answer is verifiable, it replies with the source. If not, it asks you, and only then. Risky steps (commit, deploy to a shared environment, DB writes, expensive test suites, opening a PR) are gates: the worker stops and the coordinator asks you.

```
You ── Coordinator (strong model, e.g. Opus)
          ├─ Worker T1 (cheaper model, e.g. Sonnet) ── worktree T1
          ├─ Worker T2 ─────────────────────────────── worktree T2
          └─ Worker T3 ...
```

This puts the strong model where judgment matters (clarifying, verifying, deciding what to ask you) and the cheaper model on implementation.

The coordinator is woken by worker events (question, blocked, done, failed, stalled). It doesn't poll. A status board (`status.md`) and a Q&A log (`qa.md`) live in a run folder, so a new coordinator session can pick a run back up.

## Files

| File | What it is |
|---|---|
| `SKILL.md` | The coordinator procedure. Backend-neutral |
| `worker-brief.md` | Template for each worker's first prompt |
| `backends/orca.md`, `backends/native.md`, `backends/tmux.md` | How each backend maps the coordinator's verbs (spawn, reply, read, stop, ...) to real commands |
| `scripts/spawn-native.sh`, `scripts/spawn-tmux.sh`, `scripts/wait-ready.sh` | Spawn helpers and readiness check |
| `project-config.md` | Per-project config template (worktrees, answer sources, gates, done evidence) |

## Two layers: hosting and messaging

Every setup needs two things, and they can be chosen separately:

- **Hosting**: where a worker session runs and how you can look at it.
- **Messaging**: how a worker sends QUESTION / BLOCKED / DONE and gets a reply.

| | Orca | Plain Claude Code | tmux |
|---|---|---|---|
| Hosting | Orca tab per worker | `claude --bg` background session | One tmux window per worker |
| Messaging | Orca orchestration mail (`ask`, `reply`, `worker_done`) | Claude cross-session messages (`SendMessage`) | Claude cross-session messages (tmux-hosted sessions are regular local sessions) |

tmux works only as a hosting layer. Driving workers with `send-keys` and reading them with `capture-pane` turned out fragile in testing (see below), so the tmux backend borrows native messaging.

## Comparison

All three were tested with the same task: a worker writes a file, asks the coordinator a question, waits, writes the answer to a second file, and reports done. All three completed the round trip, and the model flag was respected in each (`--model sonnet` produced `claude-sonnet-5-5`).

| | Orca | Plain Claude Code (`native`) | tmux |
|---|---|---|---|
| **Needs** | Orca app, coordinator running inside Orca | Claude Code only | tmux + Claude Code |
| **Spawning a worker** | One command (`orca orchestration worker-start`), Orca adds its own worker instructions | `claude --bg` via `spawn-native.sh` | New tmux window + one paste of the brief via `spawn-tmux.sh` |
| **Worker → coordinator** | Structured mail. Questions and done reports carry task ids, outcome, changed files | Free-text message with an `[ORCH <ticket> TYPE]` header line | Same as native |
| **Coordinator wake-up** | Only when the coordinator is idle. Mail that arrives mid-turn waits until `orca orchestration check` | Pushed into the coordinator's conversation, even mid-turn | Same as native |
| **Coordinator → worker** | `orca orchestration reply` wakes the worker | `SendMessage` wakes an idle worker | Same as native |
| **Stall detection** | Built in (`escalation` with a stop reason, `exited`, `lost`) | `notify_when_idle` subscription + `state: blocked` in `claude agents --json` | Same as native |
| **Asking the user for a decision** | Decision gates (`gate-create`) that block the task in the UI | Coordinator asks in chat | Coordinator asks in chat |
| **Watching workers** | Orca UI, one tab each, plus `orca worktree ps` | `claude agents` (agent view), `claude attach <id>` | `tmux attach`, all workers in one terminal |
| **Remote workers** | Yes, on paired Orca servers | No | Over SSH, manually |
| **Other agents (Codex, etc.)** | Yes | Claude only | Any CLI, but messaging only for Claude |
| **Add-on built here** | Docs only | 2 small scripts + header convention | 1 more script on top of native |
| **Best for** | Daily use when you already work in Orca | No extra tools, or a teammate without Orca | Teammates who live in the terminal and want every worker visible |

## What testing turned up

These are handled in the skill. They're listed here because they surprise people.

1. **Trust dialogs on fresh folders block workers silently.** The first time Claude opens a new folder it may ask about project MCP servers ("New MCP server found in this project") or external CLAUDE.md imports. A background worker stuck on one only shows `state: blocked`. Brand-new worktrees hit this. The skill detects it and tells you where to answer once. It never presses keys on a dialog for you.
2. **Permission modes must match.** Claude holds cross-session messages for manual approval when the sender and receiver run in different permission modes. Workers start in the coordinator's mode (config: `Permission mode`).
3. **Orca wakes the coordinator only when idle.** The coordinator ends its turns promptly and runs `orca orchestration check` before ending each turn.
4. **Screen scraping is unreliable.** A readiness check that looked for Claude's prompt glyph matched the trust dialog's selector, and the brief got typed into the dialog. An idle check that matched screen text failed on a non-breaking space. Readiness now comes from `claude agents --json`. The screen is only used to detect a dialog, by its `Enter to confirm` footer.

## Install

```bash
# repo already cloned at ~/Personal/agentic-workflow
ln -s ~/Personal/agentic-workflow/skills/ticket-orchestrator <project>/.claude/skills/ticket-orchestrator
cp ~/Personal/agentic-workflow/skills/ticket-orchestrator/project-config.md <project>/.claude/ticket-orchestrator.md
# fill in the config, restart the session
```

Then, in the coordinator session: "orchestrate tickets 123, 456 and 789".

Requirements: Claude Code with background sessions (`claude --bg`) and cross-session messaging. Optional: Orca, tmux. `python3` for the readiness check.

## Status

Drafted from a spike with dummy tasks. Not yet tested: a full run on real tickets, Orca decision gates in the UI, and workers in brand-new worktrees from the project's worktree script.

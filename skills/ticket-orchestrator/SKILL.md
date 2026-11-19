---
name: ticket-orchestrator
description: Use when several tickets or issues should be implemented in parallel by separate agent sessions while one coordinator session answers their questions, gates risky steps and reports progress, so the user stops switching between windows. Triggers on "orchestrate these tickets", "run tickets in parallel", "spawn workers for #1 #2 #3", "coordinator agent", "multi-ticket run", "check on my workers", "resume the orchestration run". Works on Orca, plain Claude Code background sessions, or tmux.
---

# Ticket Orchestrator

One **coordinator** session (this one, strong model) runs a **Run** of N **workers** (one session per ticket, cheaper model). Workers implement. When a worker is unsure, it asks the coordinator instead of guessing. The coordinator answers from verified sources, or asks the user. The user talks only to the coordinator.

```
User ── Coordinator (this session, e.g. Opus)
           ├─ Worker T1 (e.g. Sonnet) ── worktree T1
           ├─ Worker T2 ─────────────── worktree T2
           └─ Worker T3 ...
Worker unsure → QUESTION → coordinator verifies → reply   (not verifiable → ask user → reply)
Worker at a gated step → BLOCKED → coordinator asks user → reply
Worker finished → DONE + evidence → status board
```

Two layers, picked independently:

| Layer | Options |
|---|---|
| Hosting: where a worker lives, how the user watches it | Orca tab · `claude --bg` · tmux pane |
| Messaging: QUESTION / BLOCKED / DONE and replies | Orca mail · Claude cross-session messages (`SendMessage`) |

Supported combinations: **orca** (Orca/Orca), **native** (`claude --bg`/SendMessage), **tmux** (tmux pane/SendMessage). Each one has its own file in `backends/`.

## Step 0: Load config and pick a backend

1. Read the project config at `<workspace root>/.claude/ticket-orchestrator.md`. If it's missing, copy `project-config.md` from this skill, ask the user for the missing values one block at a time, and offer to save it.
2. Pick the backend, first match wins:
   - The user named one → use it.
   - `TERM_PROGRAM=Orca` and `orca status` shows `runtimeReachable: true` → **orca**
   - `$TMUX` is set, or the user wants every worker visible in one window → **tmux**
   - Otherwise → **native**
3. Read `backends/<backend>.md`. It maps every verb below to real commands. Read nothing else from `backends/`.

## Step 1: Plan the Run

1. Collect the tickets: ids, links, or issue numbers. For each one, find its repo and worktree using the config's **Worktrees** rule. Create missing worktrees **before** spawning (sequentially, never in parallel: creation scripts touch shared git state).
2. Run the config's **Per-ticket start actions** (e.g. assign issue, move tracker status) for each ticket, or skip them if the worker's own workflow already does that.
3. Find dependencies. FE+BE siblings of one ticket: the BE worker goes first, or the coordinator writes the API contract into both briefs. Workers that would edit the same files must not run in parallel; put them in sequence.
4. Create the run folder `<run root>/<run-id>/` (run root from config, run-id = `YYYYMMDD-HHMM`) containing:
   - `status.md`: the status board (format below)
   - `qa.md`: every question, answer and source (reused by later questions)
   - `briefs/<ticket>.md`: one filled `worker-brief.md` per ticket
5. Show the user the plan: tickets, worktree paths, worker model, backend, order/dependencies, gates. **Start nothing until the user confirms.**

## Step 2: Spawn workers

Per ticket: **spawn** (backend verb) with the worker model and effort from config, the worktree as cwd, and `briefs/<ticket>.md` as the first prompt. Then run the backend's **ready check**:

| Ready check says | Meaning | Action |
|---|---|---|
| ready / working | Worker took the brief | Note the handle in `status.md` |
| blocked / dialog on screen | Startup trust dialog (new MCP server, external CLAUDE.md imports) or a permission prompt | Tell the user exactly where to click once (backend file says how to attach), then re-check. Never send keystrokes to a dialog yourself |
| not listed after 60 s | Spawn failed | Read the backend's output, report, do not retry blindly |

Spawn all independent workers, then **end your turn**. The coordinator does not sit in a loop. It is woken by worker events.

## Step 3: Handle events

Every backend reduces to these events. Handle the whole batch before ending the turn.

| Event | Coordinator action |
|---|---|
| **QUESTION** | Answer with the procedure below |
| **BLOCKED (gate)** | The worker reached a gated step (config **Gates**). Ask the user (one question, the worker's evidence attached). Relay the decision. For a shared-resource gate (deploy target, shared DB), check `status.md`'s **Locks** first: one holder at a time |
| **BLOCKED (other)** | Worker can't continue (failing env, missing access). Fix it if it's within your permissions and the config allows. Otherwise ask the user |
| **DONE** | Check the evidence covers the brief's done list. Gaps → send the worker back with exactly what's missing. Complete → mark done, release locks, run any **On done** action from config |
| **FAILED** | Mark failed with the reason. Never mark it done. Ask the user: retry, re-scope, or drop |
| **STALLED** | Worker went idle without sending QUESTION/BLOCKED/DONE, or shows blocked. Read its last output (backend **read**). Send one steering message, or tell the user if it waits on a dialog |
| **LOST** | Session exited or vanished. Tell the user. Offer a respawn with the same brief plus "resume from the current worktree state" |

After every batch: update `status.md`, and if the user is present, reply with a short digest of changes only (not the full board).

### Answering a QUESTION

1. Check `qa.md`. If the same question was answered already, reuse the answer and cite the entry.
2. Verify against the config's **Answer sources**, in order. Code questions: query the code index **at the worker's worktree path**, not the main checkout.
3. Verified → reply with the answer plus its source (file:line, doc/article, query). Append to `qa.md`.
4. Not verifiable, a business decision, or sources disagree → **ask the user**. Reply to the worker only with the user's answer. Append it to `qa.md` with source "user, <date>".

The coordinator never makes up an answer to unblock a worker. "Probably X" is a user question, not a reply.

## Step 4: Close the Run

When every worker has settled (done/failed/dropped): give the user a final report per ticket: outcome, evidence summary, open blockers, follow-ups the workers raised. Stop or release worker sessions (backend **stop**) unless the user wants to keep using them. Leave the run folder in place.

## Resuming

A new coordinator session resumes from `<run root>/<run-id>/status.md`: re-read it, run the backend's **list** to reconcile live workers with the board, then re-attach (backend file explains how) and continue at Step 3.

## Status board (`status.md`)

```markdown
# Run <run-id> · backend: native · workers: sonnet/medium

| Ticket | Repo | Worktree | Handle | State | Waiting on | Last event |
|---|---|---|---|---|---|---|
| 13101946780 | BE | .worktrees/api-13101946780-x | t-13101946780 | working | - | 14:02 QUESTION answered (qa#3) |

## Locks
| Resource | Holder | Since |
|---|---|---|
| deploy:dev-cf | 13101946780 | 14:10 |

## Order
13101946780 BE → 13101946780 FE
```

State values: `planned · spawning · working · waiting-coordinator · waiting-user · done · failed · stalled · lost`.

## Monitoring cadence

Events drive the coordinator. Don't poll workers on a timer. A user who wants a recurring digest gets `/loop 15m` running "print status.md changes + backend list". Never use a cadence under 10 minutes: every wake of a strong model costs a full context read.

## Red flags: stop and fix

| Thought | Reality |
|---|---|
| "I'll guess the answer so the worker keeps moving" | A wrong guess costs a rework round. Verify or ask the user |
| "I'll just press Enter on the worker's dialog" | Trust and permission dialogs belong to the user. Tell them where to click |
| "Two workers can deploy at once, it's quick" | Shared targets take one lock holder at a time. Check Locks |
| "The worker said DONE, mark it done" | Check the evidence against the brief's done list first |
| "I'll check on workers every minute" | Events wake you. Polling burns tokens and finds nothing new |
| "The worker can commit/push itself" | Only if config Gates allow it. Default: the worker stops and sends the suggested message |
| "I'll relay the worker's question to the user word for word" | First check `qa.md` and the sources. Ask the user only what's left unverified |

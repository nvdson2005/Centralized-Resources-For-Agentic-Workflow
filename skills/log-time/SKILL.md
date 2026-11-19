---
name: log-time
description: Log today's or yesterday's agent-session work (Claude Code, Copilot CLI) into ClockLeap time entries following CODE LEAP's Clockify guidelines. Use when the user says "log my time", "fill my timesheet", "log activities", or "/log-time".
---

# log-time

Turn agent sessions into ClockLeap entries via the `clockleap` MCP. Preview first, write only after the user confirms.

## Hard rules
- **Only today or yesterday.** Older dates: refuse, point to the time-tracking admin + the missing-entries form. `collect.py` enforces this too.
- **Never create** projects, tasks, clients or tags (`create_*` tools are off limits). Missing project/task: stop and tell the user to ask the time-tracking admin.
- **Never invent a ticket ID.** Never log without the user's confirmation.
- No generic blocks. One entry per ticket/activity; split anything over `max_entry_hours` (4h).
- Skip meetings (they come from the calendar). 1on1s belong to CL General.

## Workflow
1. Run `python3 ~/.claude/skills/log-time/scripts/collect.py [--date YYYY-MM-DD]`. It returns sessions with cwd, branch, active minutes (idle gaps > 10 min ignored), `repo_touched`, and ID hints.
2. Read `config.json` (copy `config.example.json` to `config.json` and fill it in; it is git-ignored). Use its `workspace_id`.
3. **Decide per session whether it is client-project work.** cwd alone is not enough (a workspace root can host unrelated chats). Client work only if `repo_touched` is true, or the session worked on a client ticket. Otherwise it is non-client: plain description, no ticket ID, project = `other_default_project` unless the user says otherwise.
4. **Find the ticket (client work only).** Order: worktree folder/branch name, `documentation/tickets/` folder touched, `#id` in prompts/commits, tracker link in the session. Parent ticket ID = long number (9+ digits); GitHub issue = short number (adapt to your tracker). Not found and real ticket work: flag `⚠ no ticket found`, ask the user. Generic or tooling work (agentic workflow, skills, config): no ID, that is fine.
5. **Group** sessions by ticket; merge same-day sessions of one ticket into one entry (respect the 4h cap).
6. **Task + name** (see below), then **project** (see below).
7. **De-dupe**: call `list_time_entries` for the date; flag overlaps with existing entries.
8. **Preview table**: Project | Task | Name | Start-End | Duration | Billable? | Flags. Let the user edit rows. Ask to confirm.
9. On confirm: `log_past_time` per row. Then show the day total; warn if the week looks under 32h.

## Task and name
Ticket work (codebase research, error analysis, debugging, PR-review fixes, tests, refactor, everything for a ticket) is generalized to **Backlog Item** with verb `Implement`. Do not use finer verbs.

| Case | Entry name |
|---|---|
| Ticket with GitHub issue | `Implement GH#<issue> - #<ParentID> - <Ticket title>` |
| FE + BE issues | `Implement GH#<fe>/#<be> - #<ParentID> - <Ticket title>` |
| Parent ID only | `Implement - #<ParentID> - <Ticket title>` |

- Every ID is prefixed with `#`. Ticket title comes from the tracker ticket; ask if unknown.
- No ticket, research/spike/tool comparison: task **Research**, plain description of what and why.
- No ticket, debugging: task **Troubleshooting**, description of the error.
- Docs work: task **Documentation**, include the page title.
- Anything else: **Other**.

## Project routing (`billing_client` in config)
- Billable ticket implementation: project **Pilot Phase**.
- Research/spikes, no-ticket exploration, agentic-workflow/skill setup, anything doubtful: **Exploratory Phase** (default when unsure, never bill the client on doubt).
- Show the proposed billability in the preview; the user can flip it.
- Task ids are looked up with `list_tasks` per project (the same 8 default tasks exist in both).
- Tags: do not add unless the user asks; never create new ones.

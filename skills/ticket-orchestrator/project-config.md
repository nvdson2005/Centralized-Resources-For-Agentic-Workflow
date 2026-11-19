# Project config template for ticket-orchestrator

Copy to `<workspace root>/.claude/ticket-orchestrator.md` and fill it in. The coordinator reads it at Step 0, asks once for anything missing, and offers to save the answers.

## Run

- **Run root:** <folder for run folders, e.g. `<workspace>/.orchestrator`>
- **Backend:** <auto | orca | native | tmux>
- **Worker model / effort:** <sonnet / medium>
- **Permission mode:** <the mode the coordinator runs in, e.g. auto. Workers MUST match it (native and tmux)>
- **Max parallel workers:** <3>

## Worktrees

How to find or create a ticket's worktree. Runs sequentially before spawning.

- **Existing worktree pattern:** <e.g. `<workspace>/.worktrees/<repo>-<ticket>-*`>
- **Create command:** <e.g. `cd <repo> && bash scripts/new-worktree.sh --ticket <id> --slug <slug> --json`>
- **Post-create:** <e.g. index the code graph, link node_modules. Or "done by the create command">

## Per-ticket start actions

Run by the coordinator before spawning, unless the worker workflow does them.

- <e.g. assign the issue to the user: `gh issue edit <n> -R <owner/repo> --add-assignee @me`>
- <e.g. move the tracker item to "In progress">

## Worker workflow

The text pasted into the brief's `{{WORKFLOW}}`. Name the skills/commands the worker runs, in order.

- <e.g. Run the `pre-implement` skill, skipping its worktree step (the worktree exists)>
- <e.g. Follow the repo CLAUDE.md "Ticket Workflow" through tests>

## Answer sources

Order the coordinator checks before answering a QUESTION. Code queries use the worker's worktree path.

1. <`qa.md` of this run>
2. <business knowledge: wiki path / docs URL>
3. <code index: tool + how to point it at a worktree>
4. <data: read-only DB client command>
5. <user>

## Gates

Steps where a worker must stop and send BLOCKED. `shared` = one holder at a time (tracked in Locks).

| Gate | Shared? | Rule |
|---|---|---|
| commit / push | no | <e.g. worker sends the suggested message; user commits> |
| deploy to <env> | yes | <one worker at a time> |
| DB write | yes | <user runs it> |
| open PR | no | <after user OK> |
| <expensive suite> | yes | <ask first> |

## Done evidence

The brief's `{{DONE_EVIDENCE}}`.

- <unit tests: command + pass output>
- <API/e2e: which suite, pass output>
- <diff summary, changed files>

## On done

- <e.g. remind the user to run the PR review in a fresh session>

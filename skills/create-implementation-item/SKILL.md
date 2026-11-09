---
name: create-implementation-item
description: Use when a ticket link from any project tracker (Jira, Linear, Monday, Asana, ClickUp, GitHub or GitLab issues, Trello, Notion, Azure Boards) needs a dive into its business context and code impact to judge feasibility or effort, or when a vague feature idea needs a clear vision, a parent ticket and per-repo implementation issues. Trigger on "scope this ticket", "is this feasible", "how would we build X", "turn this idea into tickets", "create the implementation issues".
---

# Create Implementation Item

## Overview

One workflow from **a tracker ticket link or a vague idea** to **a confirmed intention, a parent item in the tracker, and one implementation issue per affected repo**, each linking the parent. An optional clarification sub-item carries the open questions.

Core principle: business logic and code are often unclear, so **every claim in the tickets is verified (knowledge sources, code from an allowed branch or its worktree) or recorded as a clarification question**, and **nothing is written to the tracker or the code host until the user approves a preview of it**.

**Violating the letter of these steps is violating the spirit.** A user in a hurry gets shorter questions, not skipped phases.

Reference files in this directory (read each when a step points to it):

| File | Holds |
|---|---|
| `project-config.md` | Template for per-project settings: tracker, owners, components, branches, tests, conventions |
| `tracker-reference.md` | Detecting the tracker from a URL, access routes, and per-tool operations |
| `code-host-reference.md` | GitHub (`gh`) and GitLab (`glab`) auth and issue commands |
| `parent-item-contract.md` | Sections of the business-level parent item |
| `implementation-issue-contract.md` | Sections of each per-repo implementation issue |

## Modes

| Input | Mode | Parent item | Implementation issues |
|---|---|---|---|
| Tracker item URL | **Ticket** | exists, read it, never rewrite it | one per affected component, linking it |
| Idea in words | **Idea** | new, per `parent-item-contract.md` | one per affected component, linking it |

## Steps

### 0. Project config and input (before anything else)

Tools are not checked in advance. Each step calls its tools when it needs them, and a failure pauses the run there (see "When a tool is unusable").

**0.1 Input.** Classify what the user gave.

| Input | Action |
|---|---|
| Empty, whitespace, or only the skill name | Stop. Ask for a ticket link, or a sentence on what should change. |
| URL whose host matches a tracker (`tracker-reference.md`, "Detect the tool") | **Ticket mode.** Step 2 reads the item. If 0.2 shows it isn't the config's tracker, say so in one line: reads and writes go to the URL's tool. |
| URL with an unknown host | Ask which tool it is and whether it's the ticket to scope. |
| A bare id (`PROJ-123`, `#45`, a number) | Ask which item it is. If the config names a tracker, propose the URL. |
| Text naming a change and who or what it affects | **Idea mode.** |
| Text with no clear intention ("improve the dashboard") | Ask one question: what should change, and for whom? Repeat until the answer names a change. |
| A link plus text | **Ticket mode.** The text steers the step 4 focus. |
| Not a product change (debugging, code review) | Say this skill doesn't fit, name a better one if obvious, and stop. |

Only an input that lands in a mode goes on to 0.2.

**0.2 Config.** The workspace root is the directory the session started in (the folder holding the component repos, or the repo itself). Load the project's filled config: `<workspace root>/.claude/create-implementation-item.md`, else `<workspace root>/create-implementation-item.md`. Also read `CLAUDE.md` / `AGENTS.md` at the root and in each repo for hints.

- **Needed for every run:** components (repo, local path, allowed branches, worktree branch). **Idea mode also needs:** the tracker and where parent items go. Everything else can stay empty. With no owner names, clarification questions are grouped by role only and no one is mentioned.
- **Missing a needed field:** send **one** message with those `project-config.md` fields filled with your best guesses, guesses marked, and ask the user to correct them. Guess from: the hints; git repos under the root with `git remote get-url origin` and their default branch (`git symbolic-ref refs/remotes/origin/HEAD`); for tracker ids, the tracker's list calls (projects, teams, boards). Offer to save the result to `<workspace root>/.claude/create-implementation-item.md`.

Then say the mode and create one todo per step below.

### When a tool is unusable (every step)

A tool is unusable when its call fails: not connected, auth or permission error, repo or item not found, or a timeout on the second try. First try the other routes to the same tool: load deferred tools with ToolSearch, the tool's CLI for its MCP (or the reverse), another logged-in account (`code-host-reference.md`, "Auth"). If none works:

1. **Pause in place.** Don't skip the step, don't guess its result, don't start a later step, and don't try the next write in step 6.
2. **Tell the user** in one message: the step, the tool, the exact error, and the fix they can apply (each step's **If blocked** line lists the usual ones).
3. **Wait.** On "done" or "retry", repeat the failed call and continue from there. Never redo calls that already succeeded.
4. **The user may choose instead:**
   - **Skip a source** (a knowledge source, the code index) for the rest of the run. Claims only it could confirm are marked `(unverified)` in the summary and become Open Questions in the drafts.
   - **Skip a system's writes** (tracker or code host). Its step 6 writes are dropped and their drafts stay in chat to paste by hand. Skipping both is a **draft-only** run. In Ticket mode without the code host, tell the user to search each repo for the parent id first, since the duplicate check didn't run.

A user who says up front that a tool won't work ("no GitHub today") has made that choice already: confirm it in one line and carry on. A tool-permission prompt the user denies is their decision, not a failure: ask whether to retry (the Gate 1 yes still holds, since nothing changed) or skip that system's writes.

### 1. Code baseline (worktree when needed)

Code facts come only from a component's **allowed branches** (config). For each component repo, run:

- `git -C <repo> branch --show-current`
- `git -C <repo> status --short`
- `git -C <repo> fetch -q origin <current branch>`, then `git -C <repo> rev-list --count HEAD..origin/<current branch>`

Then pick where to read code from:

- **Allowed branch, clean tree, 0 commits behind:** the checkout itself. No message needed.
- **Allowed branch, clean tree, but behind:** the worktree below with `B=<current branch>`.
- **Anything else** (feature branch, uncommitted changes): a detached, read-only worktree of the component's worktree branch (config). Never switch, stash or reset the user's checkout. Never edit files in the worktree. Keep it for the next run.

  ```bash
  B=<worktree branch from config>
  WT=<workspace root>/.worktrees/<repo>-scoping   # outside the repo, so a repo-level code index can't resolve to the checkout
  git -C <repo> fetch -q origin $B
  if [ -d "$WT" ]; then git -C "$WT" checkout -q --detach origin/$B
  else git -C <repo> worktree add -q --detach "$WT" origin/$B; fi
  ```

  - Tell the user in one line, e.g. "`<repo>` has uncommitted changes, so I'm reading code from a worktree of `origin/<B>` at `<WT>`."
  - **Code index** (if the config names one): build it for `<WT>` the first time, refresh it on reuse, and point every query for that repo at `<WT>`, never at the checkout. If indexing fails, use the checkout's index only to locate symbols and confirm each cited fact by reading the same path in `<WT>`.
- **Fetch fails** (offline, auth): tell the user, read the checkout, and mark code findings "(from `<branch>`, not verified against `<B>`)".
- **If blocked:** a repo is missing at its local path (fix: clone it), or `git worktree add` fails (fix: `git worktree prune`, or free the path). Pause.

### 2. Gather the ticket (Ticket mode only)

- Read the item with its description, comments and sub-items (`tracker-reference.md`, "Read item"). If it doesn't exist, stop and ask for the right link.
- Look for existing implementation issues: search each component repo for the item id and URL (`code-host-reference.md`), and scan the item's comments and links for issue references. If the config keeps implementation items as tracker sub-items, check the item's children instead.
- An issue counts as existing only if its body links this item. A bare number match is not enough: show the hit and ask. Existing issues and an existing clarification sub-item get **edited** (with approval), never duplicated. When only some components have one, plan edits for those and creates for the rest.
- **If blocked:** tracker tools missing or erroring (fix: connect or re-auth that tool's MCP or CLI). Code host search fails after the account fallback (fix: log in with an account that can see the repo). Pause. Skipping doesn't help for the tracker read: the ticket is the input.

### 3. Context sweep (before the first question)

Work through the config's **knowledge sources** in their listed order, then the code, and keep a source for every finding:

1. **Docs and wiki:** search for the ticket id and for every decision, feature and term the input mentions.
2. **Code:** for each affected feature, query the code index (or search) in the step 1 code source.

A question the sweep already answered is not asked. State the answer and its source instead.

**If blocked:** a remote doc source fails (fix: network, auth, retry later), or the code index fails (fix: install or rebuild it). Pause. The same applies to code lookups in step 4.

### 4. Validate the intention

The goal is a confirmed intention, not a document. No spec file, no design doc, no plan.

**Questioning rules:**

- One question per message, a single sentence, in the user's vocabulary.
- Follow it with 2-4 short example answers the user can pick, combine or ignore, e.g. "(a) before the run starts, (b) during the run, (c) both". Mark your recommended one. Leave them out only when no realistic set exists.
- On "just guess", propose something concrete. A guess they can correct often beats a question.
- Think through several approaches privately. Show a comparison only when it helps them decide.
- Once you understand a part, play it back with guesses marked, and ask what's wrong or missing.
- In a hurry: fewer, sharper questions. A default said out loud counts, because they can reject it.
- The clarification-list yes/no ask (below) doesn't count as the message's one question.
- On "that's all I know" or "wrap up", send the scoping summary now. Every open point becomes an assumption.

**Ground to cover** (territory, not a script): the business concept and why it matters now; which roles and features it touches; what changes in each component; feasibility, effort and risks.

**The user can't answer** ("no idea", "ask the PO"):

1. Try to answer it yourself from step 3's sources. If the user routed a code question to the technical owner, answer it from the code and say why you didn't route it.
2. Still open? Ask "Add this to the clarification list?" in the same message as your next question (on its own if none is left).
3. On yes, add it with its owner role, state the assumption you'll continue with, and mark it `(assumed, to confirm)`.
4. On no, the user picks the assumption. It becomes their decision, not a list item.

**Owner rule** (names from config):

- **Business owner:** behavior, roles, wording, rules, priorities.
- **Technical owner:** only what code and docs can't settle: production infrastructure, data scripts, scheduled jobs, environment config, external systems.

**Stale or ambiguous terms** (a renamed concept, a vague noun like "the report"): pin the meaning down with the user first. Only if they can't does it become a business-owner question.

**Scoping summary (ends step 4).** One message, in order:

1. **Intention:** what changes, for whom, why now (2-3 sentences)
2. **Decisions:** one line each
3. **Assumptions:** each marked `(assumed, to confirm)`
4. **Impact per component:** one line each with its source (doc, code path). No source: look it up before sending; still none, mark `(unverified)`. Never invent a path.
5. **Feasibility:** a verdict, a size per component (S/M/L), the main risks
6. **Clarification list:** question, owner role, current assumption; or "None"

End with "Is this right?" and loop until the user explicitly confirms. The confirmed summary is the only input to step 5.

### 5. Draft the parent item and the issues (inline preview)

Show every draft **inline in chat**, one fenced markdown block per document, fenced with four backticks (````` ````markdown `````) so inner code and mermaid blocks don't break it. No local files. The latest version in chat is the source for step 6.

1. **Parent item, only when none exists (Idea mode):** per `parent-item-contract.md`. The whole clarification list goes in its Open Questions. Related shows `TBD` for the issues. The title follows the config's title convention.
2. **Implementation issues (both modes):** one per affected component, per `implementation-issue-contract.md`.
   - Each starts with the parent link. In Idea mode it's `TBD` until step 6 creates the parent.
   - A component the summary lists with no work gets no issue: say so and ask before dropping it. Never pad.
   - Ticket mode (the parent is not rewritten): technical clarification questions also go in the affected issue's Open Questions.

Show the drafts **with the Gate 1 table** (step 6). After a change, re-show only the changed draft plus the table.

**Draft-only run** (the user skipped both systems' writes): the inline drafts are the deliverable.

### 6. Tracker and code host writes

- **Gate 1.** One table listing every write:

  | # | Where | What | Title | Details |
  |---|---|---|---|---|
  | 1 | tracker `<project/board>` | create parent (Idea mode) | per title convention | type, status, fields from config (e.g. reporter = you), description = the parent draft above |
  | 2..n | `<repo>` | create (or edit `#n`) issue | … | label, body = that component's draft above |
  | n+1 | parent item | link issues | (none) | Idea: rewrite own Related section. Ticket: the exact comment text |

  - Config keeps implementation items as tracker sub-items: rows 2..n are sub-items under the parent, created per `tracker-reference.md`.
  - Assignees stay empty unless the user names someone.
  - A yes ("yes", "create them", "go") given while the table is on screen passes the gate. "Summary confirmed", or "set up the tickets" said before the table was shown, does not.
- **Execute in this order**, verifying each write by reading it back:
  1. **Parent (Idea mode):** create it and write its description (`tracker-reference.md`). Fill its link into every issue draft.
  2. **Issues:** create each (`code-host-reference.md`), then fill sibling links and edit them.
  3. **Link back to the parent** (`tracker-reference.md`, "Link issues back").
  - Text changes only for the ids and links this step fills in. Anything else needs a new Gate 1.
- **If blocked** mid-way: list what already exists (with links, and say if a description was pasted by hand rather than read back) and what is still to do, then pause. On resume, continue with the failed write. Never re-create something that exists.
- **Clarification list not empty:** ask "Post the N clarification questions to the tracker?"
  - On yes: reuse or create the clarification sub-item (name from config). **Gate 2:** preview the comment, plus the sub-item creation if it's new, and wait for a yes. Then post one comment that mentions only the owners who have questions in it, and read it back.
  - On no: post nothing. The questions stay in the drafts' Open Questions; list them in the wrap-up.

### 7. Wrap up

- List every link created and anything that failed or was skipped.
- If decisions were made and the config names a knowledge-capture step, remind the user of it.

## Red Flags: STOP

| Thought | Reality |
|---|---|
| "User's in a hurry, skip validation and write the tickets" | Fewer, sharper questions. The summary still needs a confirmation. |
| "The input is vague, step 4 will sort it out" | Step 0 first: one question until the input names a change. |
| "I'll check every tool up front" | No pre-checks. Each step calls its tools when it needs them. |
| "That tool failed, I'll skip it and carry on" / "I'll fill in what it would have said" | Pause, report the exact error and the fix, and wait. Only the user can choose to skip. |
| "No config, I'll assume the repos and branches" | Ask once with your guesses marked, then continue. |
| "I'll write a spec / design doc first" | No spec. The confirmed summary goes straight into drafts. |
| "Feature branch, I'll read it and flag it" / "I'll switch or stash their branch" | Use the read-only worktree. Never touch the checkout. |
| "Summary confirmed, they asked for tickets, so create them" | Gate 1 needs a yes given while its table is on screen. |
| "The parent exists, I'll tidy its description" | Ticket mode never rewrites the parent. Link the issues with one comment. |
| "Repo not found, so issues are impossible" | Often the wrong active account. Try the account fallback first. |
| "The technical owner would know where this lives in code" | The code knows. They get only what we cannot determine. |
| "I'll post the questions now" | Only after the parent and issues exist, only on yes, only after the Gate 2 preview. |

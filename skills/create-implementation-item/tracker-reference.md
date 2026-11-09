# Tracker reference

The tracker holds the parent item, its comments and the clarification sub-item. Never guess an id (board, project, team, issue type, user, field): look it up with the tool's info or schema calls first.

## Detect the tool

| URL shape | Tool | Item id |
|---|---|---|
| `<x>.monday.com/boards/<board>/pulses/<id>` | Monday | `<id>` (board `<board>`) |
| `<x>.atlassian.net/browse/<KEY-n>`, or `...?selectedIssue=<KEY-n>` | Jira (Cloud) | `<KEY-n>` |
| `<self-hosted host>/browse/<KEY-n>` | Jira (Server/DC) | `<KEY-n>` |
| `linear.app/<workspace>/issue/<KEY-n>/<slug>` | Linear | `<KEY-n>` |
| `app.asana.com/0/<project>/<task>`, `app.asana.com/1/<ws>/project/<p>/task/<task>` | Asana | `<task>` |
| `app.clickup.com/t/<id>` (or `/t/<team>/<custom-id>`) | ClickUp | `<id>` |
| `github.com/<owner>/<repo>/issues/<n>` | GitHub Issues | `<owner>/<repo>#<n>` |
| `gitlab.com/<group>/<project>/-/issues/<n>` (or the config's self-hosted host) | GitLab Issues | `<group>/<project>#<n>` |
| `trello.com/c/<shortLink>/<slug>` | Trello | `<shortLink>` |
| `notion.so/<...>-<32 hex>`, `<x>.notion.site/...` | Notion | page id (the 32 hex) |
| `dev.azure.com/<org>/<project>/_workitems/edit/<n>` | Azure Boards | `<n>` |
| anything else | ask the user which tool it is | |

## Access routes (try in order)

1. **MCP server for that tool.** Its tools may be deferred: load them with ToolSearch (search the tool's name). Tool names vary between servers, so list them before the first call.
2. **The tool's CLI**, if installed and logged in: `gh`, `glab`, `jira` (jira-cli), `az boards`, or another the user names.
3. **REST/GraphQL API** with a token the user already has in an env var (ask for the var name, never for the token itself).

None works: pause per SKILL.md, "When a tool is unusable".

## Operations

Each row is what the skill needs. The patterns are starting points: confirm names against the connected server's tool list.

| Operation | Monday | Jira | Linear | GitHub / GitLab Issues |
|---|---|---|---|---|
| **Read item** (description, comments, sub-items, links) | `get_board_items_page` with description, sub-items and columns; `get_updates` | get issue (expand comments, subtasks, issue links) | get issue; list comments; children | `gh issue view <n> -R o/r --comments` / `glab issue view <n> -R g/p --comments` |
| **Create parent item** | `create_item(boardId, groupId, name, columnValues)` | create issue (project key, issue type from config) | create issue (teamId, title) | `gh issue create` / `glab issue create` |
| **Write description** | GraphQL `set_item_description_content(item_id, markdown)` (replaces it all) | `description` on create or edit; check the content format (ADF vs markdown) the server expects | `description` (markdown) on create or update | body on create, or `issue edit` |
| **Post comment** | `create_update` (HTML) | add comment | create comment | `gh issue comment` / `glab issue note` |
| **Create sub-item** | `create_item` with `parentItemId` | issue type Sub-task with `parent` | create issue with `parentId` | sub-issue if enabled, else a new issue linked from a task list in the parent |
| **Mention people** | `mentionsList` with user ids | account id mention (look up the id first) | user mention by handle or id | `@login` in the text |
| **Set fields** (status, reporter, priority) | column values JSON, ids from board info | fields by id, from create-meta | `stateId`, `priority`, `assigneeId` | labels, assignees, milestones |

Asana, ClickUp, Trello, Notion, Azure Boards and others follow the same rows: read the item, create in the project/list/board/database from config, write the description or body, comment, create a subtask/child, mention, set fields. Discover ids with that tool's project, list, field or schema calls.

## Reading a ticket (step 2)

- Read the description, all comments with replies, sub-items and linked items.
- Not found: check whether the id is a sub-item and scope its parent instead. Otherwise stop and ask for the right link.
- **Existing sub-item match:** compare names trimmed and case-insensitive. The clarification sub-item must match the config name exactly.

## Creating the parent (Idea mode)

- Name = the approved title (title convention from config). Never use an em dash as a separator.
- Set the status and fields from config. For a reporter field, read the current user (the tool's "me"/"viewer"/"myself" call) right before creating.
- Where the create call takes a description or body (Jira, Linear, GitHub, GitLab), send the description there in the same call, then read back.
- Read the item back. Any field from config that came back empty: set it with the tool's update call.

**Sub-items by tool:** a Jira Epic can't hold Sub-tasks, so under an Epic create a child issue (e.g. Task) with `parent` = the epic; under a Story or Task, use Sub-task. Linear and GitHub nest any issue. Monday sub-items land on the board's linked sub-item board.

## Writing the description

1. Prepare the markdown: drop the `# Title` line and the metadata block (the item's name and fields already hold them). Convert to the tool's format if it doesn't take markdown (HTML for Monday updates, ADF for some Jira servers).
2. Write it, then **read it back**. Verified only if the call reported success and the read-back contains every section heading.
3. Failed or unverifiable:
   - Tell the user the exact error.
   - Don't loop on retries. Offer (a) the user pastes the draft shown in chat (title and metadata left out), or (b) post it as the item's first comment.
   - Some APIs can't read back a description set in the UI. Then ask the user to confirm all sections show once in the item view.
   - Never claim the description is set without a read-back or that confirmation.

Example (Monday): `create_item` can't set a description and a new item has no description doc, so use the GraphQL mutation `set_item_description_content(item_id: $id, markdown: $md) { success error }` through the generic API tool. It has returned `INTERNAL_SERVER_ERROR` on some boards: then go straight to fallback (a).

## Link issues back (step 6)

- **Idea mode (we wrote the parent):** fill the issue references into its `## Related` section and re-run the description write. Replacing our own content is safe.
- **Ticket mode (the parent already existed):** never rewrite its description. Post one comment, previewed at Gate 1:
  ```
  Implementation issues for this ticket:
  - <component>: <repo>#<n> <title> (<url>)
  ```
  Read it back: the newest comment must contain every issue link.

## Clarification comment (Gate 2 preview, then post)

One comment on the clarification sub-item, in the tool's format. Include an owner's section only if that owner has questions, and mention only those owners.

```
Hi <business owner>, <technical owner>,
While scoping <parent title> we have a few open points we can't settle ourselves:

Business (<business owner>)
1. <question, answerable without knowing the code>

Technical (<technical owner>)
1. <question + what we already checked>

Until we hear back we're assuming: <assumption per question>.
```

If the sub-item doesn't exist, its creation is part of the Gate 2 preview. Read the comment back after posting.

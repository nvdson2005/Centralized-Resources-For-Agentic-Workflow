# agentic-workflow

Agent skills for product and engineering workflows.

## Skills

### create-implementation-item

Takes a ticket link from any tracker (Jira, Linear, Monday, Asana, ClickUp, GitHub or GitLab issues, Trello, Notion, Azure Boards) or a rough feature idea. It reads the business context and the code, confirms the intention with you one question at a time, and then drafts:

- a business-level parent item in your tracker (only when there isn't one yet)
- one implementation issue per affected repo, linked to the parent

Nothing is written to the tracker or the code host until you approve a preview. If a tool fails along the way, the skill pauses and tells you how to fix it.

Each project sets its tracker, people, repos, branches and test tools in a small config file. Start from `skills/create-implementation-item/project-config.md` and save the filled copy as `<workspace root>/.claude/create-implementation-item.md`. If it's missing, the skill asks for the values on the first run and offers to save them.

## Install

Symlink the skill into your Claude Code skills folder:

```bash
git clone <this repo> ~/Personal/agentic-workflow
mkdir -p ~/.claude/skills
ln -s ~/Personal/agentic-workflow/skills/create-implementation-item ~/.claude/skills/create-implementation-item
```

For one project only, link it into that project's `.claude/skills/` instead. Restart the session, then trigger it with "scope this ticket <url>" or "turn this idea into tickets".

Requirements: `git`. The tracker's MCP server or CLI for reads and writes. `gh` or `glab` for issues. A code index tool is optional.

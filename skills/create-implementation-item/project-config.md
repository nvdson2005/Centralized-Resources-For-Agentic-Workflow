# Project config template for create-implementation-item

Copy this to `<workspace root>/.claude/create-implementation-item.md` and fill it in. The skill reads it first, asks once for anything a run needs that is missing, and offers to save the answers here.

## Tracker

- **Tool:** <Jira | Linear | Monday | Asana | ClickUp | GitHub Issues | GitLab Issues | Trello | Notion | Azure Boards | other>
- **Base URL / workspace:** <e.g. https://acme.atlassian.net, linear.app/acme, acme.monday.com>
- **Where new parent items go:** <Jira project key + issue type (Epic/Story) | Linear team | Monday board id + group id | ...>
- **Status for a new parent item:** <e.g. New, Backlog, To Do>
- **Fields to set on create:** <e.g. reporter = current user (field id), priority = "To be prioritized", labels>
- **Clarification sub-item name:** Requirements Clarification
- **Title convention:** <none | prefix scheme, e.g. "<Area> - <title>" with the allowed areas listed here>

## People (roles)

Leave a role empty to group its questions by role without mentioning anyone.

| Role | Name | Tracker user id / handle | Owns |
|---|---|---|---|
| Business owner | | | behavior, roles, wording, rules, priorities |
| Technical owner | | | infra, environment config, data scripts, scheduled jobs, external systems |

## Components

One row per repo that implementation issues can go to.

| Component | Kind | Repo (host:owner/name) | Local path | Allowed branches | Worktree branch | Issue labels (feature / bug) |
|---|---|---|---|---|---|---|
| <API> | backend | <github:acme/api> | <~/code/api> | <main, develop> | <develop> | <enhancement / bug> |
| <Web app> | frontend | <gitlab:acme/web> | <~/code/web> | <main> | <main> | <feature / bug> |

**Implementation items live in:** <code-host issues per repo (default) | tracker sub-items under the parent>

## Tests (per component)

| Component | Unit / integration | E2E | Where E2E cases live |
|---|---|---|---|
| <API> | <pytest> | <API suite, e.g. Postman, Hurl, REST client> | <e2e/endpoints/<resource>/> |
| <Web app> | <Vitest + Testing Library> | <Playwright, or "manual Given/When/Then"> | <tests/e2e/> |

## Knowledge

- **Code index (optional):** <none | tool + build/refresh commands per path, e.g. `<tool> init <path>` / `<tool> sync <path>`>
- **Knowledge sources, in search order:** <docs/wiki path, product docs URL, ADR folder>
- **Glossary rule:** <e.g. "use the current term the wiki marks as renamed">
- **Knowledge-capture step after decisions (optional):** <e.g. a command that ingests the ticket into the wiki>
- **Copy / i18n (frontend):** <none | helper or key format for user-facing strings>

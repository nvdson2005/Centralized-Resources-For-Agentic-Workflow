# Implementation issue contract (one per component)

Developer work lives in one issue per affected component repo (config, "Components"), each linked to the parent item. If the config says implementation items live in the tracker instead, the same contract applies to sub-items created under the parent.

## Research sources

- **Code claims** (Architecture, API Changes, Affected Pages, Root Cause, Files to Change) cite code read from the step 1 code source: an allowed branch, or its read-only worktree. Use the code index if the config names one.
- **Business terms** come from the config's knowledge sources.
- A claim found in none of them goes under Open Questions, never asserted.

## Shared header (every component)

1. **Title:** a plain imperative title, no id and no `[FE]`/`[BE]` prefix (the repo already says which side it is).
2. **First body line:** the parent and sibling links:
   ```
   **Parent:** [<parent title>](<parent url>) · **Related:** <repo>#<n>, <repo>#<n>
   ```
   List every sibling issue. Write `TBD` until a sibling exists; leave it out if there are none.
3. **Label:** feature or bug label from config, set with the CLI flag, never written into the body.

## Backend (service / API) contract

1. **`## Context`**: 2 to 4 sentences on what changes in this service and why, from the parent's point of view.
2. **`## Flow: current → new`**: two ```` ```mermaid ```` `flowchart` blocks through services, endpoints and data stores, changed nodes marked (e.g. `:::changed` with a `classDef`). A brand-new flow gets only the new chart, plus "No current flow."
3. **`## Architecture`**: an endpoints table, then data model changes (tables, columns, defaults) or "None":
   ```
   | Method | Path | Handler | New / Changed / Removed | Contract delta |
   ```
4. **`## Root Cause`** *(bugs only)*: 1 to 2 sentences naming the file and function.
5. **`## Implementation`**: one `###` sub-step per change, one line each. A code block only when it IS the change.
6. **`## Deployment & Data`**: what the technical owner's team must run or provide per environment: migrations, data scripts, environment variables, scheduled jobs, config. "None" if nothing.
7. **`## Test Cases`**: the E2E/API cases in the project's suite (config, "Tests"):
   ```
   | Case | Location | Setup | Expected |
   ```
   Cover the happy path, an auth failure, a validation failure, and each edge case in Acceptance Criteria. If the suite lives outside this repo, list cases here and never under Files to Change. Add unit/integration cases as rows too when the config names a framework.
8. **`## Acceptance Criteria`**: up to about 6 checkable bullets, one clause each.
9. **`## Files to Change`**: a fenced block of paths with `← what changes` annotations.
10. **`## Open Questions`**: technical points code and docs can't settle, owner technical owner. "None" if none. "Where is X in the code" is never an open question: look it up.

## Frontend (UI) contract

1. **`## Context`**: 2 to 4 sentences on what changes for the user and why.
2. **`## API Changes`**: or "None":
   ```
   | Endpoint | Change (new / changed contract / removed) | Consumed in (service / hook / store) |
   ```
3. **`## Affected Pages`**:
   ```
   | Route / page | Component | Change |
   ```
4. **`## User Flow`**: one ```` ```mermaid ```` `flowchart` of the new flow through the screens, changed steps marked, or "No flow change".
5. **`## Root Cause`** *(bugs only)*: 1 to 2 sentences naming the component or hook.
6. **`## Implementation`**: one `###` sub-step per change, one line each.
7. **`## Copy & Translations`**: new or changed user-facing strings, in the config's i18n key format with their source-language text. "None" if none.
8. **`## Tests`**:
   - **Unit** (framework from config): `| Test file | Case | New / Refined |`
   - **E2E**: cases for the config's E2E tool, or, if there is none, `Given / When / Then` scenarios to run by hand on a test environment and reuse for acceptance testing.
9. **`## Acceptance Criteria`**: up to about 6 checkable bullets.
10. **`## Files to Change`**: a fenced path block with `←` annotations.
11. **`## Open Questions`**: technical points, owner technical owner, or "None". Business questions belong in the parent.

## Other components (worker, mobile, infra, library)

`## Context`, `## Change` (the interface or behavior that changes, as a table if there are several), `## Root Cause` *(bugs only)*, `## Implementation`, `## Deployment & Data` (if it runs somewhere), `## Tests` (framework from config), `## Acceptance Criteria`, `## Files to Change`, `## Open Questions`.

## Brevity

An issue is a scannable spec, not an essay. Tables, mermaid charts and code carry the load; prose connects them. Each section is the shortest form that meets the contract, each point is written once, and the parent is linked, not restated.

## Common mistakes

- **Wrong contract for the component** (Affected Pages in a backend issue).
- **Missing parent link.** Every issue opens with it.
- **ASCII flow blocks.** Use mermaid.
- **Test rows without cases.** Each row names a concrete case, where it lives, and its expected result. "Add tests" is not a case.
- **Vague code claims** with no file, endpoint or component.
- **Business questions in issues.** They belong in the parent.
- **Local references.** Readers see only the tracker and the code host.

## Voice

Applies to Context, Root Cause, Implementation lines and bullet lists. Tables, mermaid, paths and `←` annotations are exact technical content and stay as they are.

- Plain and direct, short sentences, active voice. No filler or hype words.
- **No em dashes at all.** No `—`, no `--`, no inline `---`. Check this last.

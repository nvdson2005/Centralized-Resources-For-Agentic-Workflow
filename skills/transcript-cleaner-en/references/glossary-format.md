# Glossary Format

All glossary files at every scope (general, tech, company, project, shared) use the same entry format.

## Entry format

Two-line entries, one per term:

```
variant1, variant2, variant3 → correct form
  Description: <one-sentence explanation of what this term means>
```

- **Variants**: misrecognized versions produced by speech-to-text. Comma-separated. Match case-insensitively.
- **Arrow**: the Unicode arrow character `→`.
- **Correct form**: the intended spelling or name. Preserves intended casing (use "ACME", not "acme").
- **Description**: required. One short sentence describing what the term means and when it's used. Helps Claude apply the entry correctly and helps the user verify entries during pending-file review.

### Examples

```
Akmee, Ackme → ACME
  Description: The company name; always capitalized.

GIA, Gia, Kia, Jera → Jira
  Description: Project tracking tool used company-wide.

Pri, Pi, Prea → Priya
  Description: Engineering team member; appears across multiple projects.

Cordex, Cortes → Cortex
  Description: A survey tool used by ExampleApp for customer feedback collection.

Adam (in agenda/list context: "next Adam on the list") → item
  Description: Common misrecognition of "item" when speakers refer to agenda points or list entries.
```

## Rules

1. **One correct form per entry.** All variants of the same term belong on the same line.
2. **Real data only.** Variants must come from actually-observed Tactiq misrecognitions, not from speculation about how a word might be misheard. AI-imagined variants are usually wrong and pollute the glossary.
3. **Description is required.** Every entry must have a description. If you don't know what the term means, ask before adding it; don't make something up.
4. **Preserve intended casing** in the correct form.
5. **One entry per line** (not counting the description line). No multi-line variant lists.
6. **Context-dependent triggers**: when a variant is also a real English word (Adam, item, school), include the trigger context in the variants column itself (e.g., `Adam (in agenda/list context: "next Adam on the list")`). The description should reinforce when the correction applies.

## Auto-inferred descriptions

When Claude proposes a glossary addition during cleaning, it generates a `[auto-inferred — please verify]` description using these sources, in priority order:

1. The Tactiq **Highlights section** of the transcript.
2. The **surrounding transcript context** (5–10 sentences around each occurrence).
3. **Reference materials** in the working folder, if any apply.
4. **Past meetings**, if loaded.

Auto-inferred descriptions are starting points, not commitments. During pending-file review, the user accepts, edits, or rewrites them.

## Categories

Group entries under `##` headings. Suggested starter categories:

**Terminology glossaries** (general, tech, company, project, shared):
- Tools & Platforms
- Methodology & Process
- Technical Terms
- Business & Roles
- Context-dependent corrections

**People and terms** (in `projects/<project-name>.md` and `projects/shared/<client>.md`):
- Engineering
- Product & Management
- Design
- QA & DevOps
- Other

Section names should evolve naturally with usage. Rename, add, or remove sections as patterns emerge in your real data.

## People at different hierarchy levels

A person may have different roles on different projects (e.g., lead engineer on one project, developer on another). Handle this by scoping roles correctly:

- **Company-level** (`glossary-company.md`): name + variants + general descriptor (e.g., "engineering team — appears across multiple projects"). No project-specific role.
- **Shared client-level** (`projects/shared/<client>.md`): client-side people who appear across multiple projects for that client.
- **Project-level** (`projects/<project-name>.md` → `## People`): name + variants + project-specific role (e.g., "lead engineer on this project").

When a project loads, all relevant scopes load together. The most-specific level provides project-specific context; less-specific levels ensure name variants are always recognized even when a person appears on a project where they don't have a role entry.

## Scoping rule — where does an entry belong?

Add an entry to the file matching its scope:

| Term type | Target file |
|---|---|
| Universal non-engineering term (sprint, Slack, stakeholder) | `glossary-general.md` |
| Engineering-specific term (Kubernetes, React, OAuth) | `glossary-tech.md` |
| ACME people, brand, internal terms | `glossary-company.md` |
| Client-spanning term or person (shared across multiple projects for that client) | `projects/shared/<client>.md` |
| Project-specific term (codename, features, project tools) | `projects/<project-name>.md` → `## Terms` |
| Project-specific person (their role on this project) | `projects/<project-name>.md` → `## People` |

When Claude proposes adding a variant that's already tracked at a different scope, update the existing entry. Do not create duplicate entries in multiple files.

## Tech vs. General — borderline cases

If a term could plausibly belong in either Tech or General, apply this rule:

- **Tech glossary** = vocabulary that requires engineering context to understand. Examples: Kubernetes, Postgres, React, API, REST, OAuth, Docker, microservices, GraphQL.
- **General glossary** = vocabulary used across business functions, not specific to engineering. Examples: sprint, standup, retrospective, stakeholder, deliverable, scope, Slack, Zoom, Notion, Jira, Figma, kickoff.

**Decision rule**: if the term is meaningful to non-engineers in ACME, it's General. If it requires engineering context, it's Tech.

If Tech ends up tiny after a few months of usage (under ~20 entries), consider folding it back into General with a section header.

## Glossary addition criteria

Claude proposes new entries to `glossary-additions-pending.md` for user review. Nothing is written to glossary files until explicit approval. Propose ONLY terms meeting ALL of:

1. **Recurring**: appeared at least 2 times in the current transcript, OR is a type that obviously recurs (tool name, project codename, feature name, recurring person).
2. **Clearly a misrecognition**: Claude has high confidence the variant is a speech-to-text error, not a legitimate term.
3. **Scope-appropriate**: the term has a clear scope (general / tech / company / client / project). Skip ambiguously-scoped terms.

When the proposed variant is a real English word ("badass", "item", "school"), the proposal must include a usage-context note. If you cannot reliably define the trigger context, do not propose — the user can add it manually later.

**Do NOT propose**:
- One-off name mentions (person mentioned once in this transcript — correct in transcript if needed, but do not propose for the glossary)
- Numbers, dates, quantities
- Terms where Claude is uncertain about the correct form
- Terms that look like arbitrary utterance, not vocabulary
- Variants that are common English words AND for which you cannot reliably define the trigger context

### High-priority threshold

When the variant appears **15 or more times in the source transcript**:
- Prefix the anchor line with `⚠️` (e.g., `⚠️ **[GA-NNN]** | decision: pending`)
- Add: `Priority: HIGH — appeared <N> times in this transcript. Review promptly to avoid accumulating errors in future runs.`
- Call it out explicitly in the end-of-run summary above the standard GA list block

The threshold is deliberately strict — 15+ occurrences indicates a systemic STT error that will repeat in every future meeting. Below threshold, the normal entry format applies (no ⚠️, no Priority line).

### Target file selection

| Term type | Target file |
|---|---|
| Universal non-engineering term (sprint, Slack, stakeholder) | `glossary-general.md` |
| Engineering-specific term (Kubernetes, React, OAuth) | `glossary-tech.md` |
| ACME people, brand, internal terms | `glossary-company.md` |
| Client-spanning term or person (multiple projects, same client) | `projects/shared/<client>.md` |
| Project-specific term or person | `projects/<project-name>.md` |

### Merging vs. creating new entries (at approval time)

Before writing an approved proposal to the target glossary file, check whether the file already contains an entry with the same correct form:

- **Exists**: extend the existing entry's variant list. Do not create a duplicate line. Example: file has `Cordex → Cortex`, approved proposal adds `Cortes` → update to `Cordex, Cortes → Cortex`. Preserve the existing description.
- **Does not exist**: append a new line in the named category section with the description.

### Description field for auto-proposals

Every proposed glossary addition includes a `Description` field marked `[auto-inferred — please verify]`. Generate it using these sources in priority order: (1) Tactiq Highlights section, (2) surrounding transcript context (5–10 sentences per occurrence), (3) reference materials in the working folder, (4) past meetings if loaded. Keep to one short sentence. The user accepts, edits, or rewrites during review.

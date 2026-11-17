---
name: transcript-cleaner-en
description: Clean English-language Tactiq meeting transcript exports (.md or .txt files from Tactiq) by correcting misrecognized words, tool names, project names, and people's names. Use this skill when the user provides or references a Tactiq transcript file and asks to clean, fix, correct, or polish it. Never summarizes, never paraphrases, never invents content. English only — refuses German or non-Tactiq inputs.
compatibility: Requires Claude Code — needs filesystem read/write to produce cleaned files, update glossary-additions-pending files, and update open-questions files.
---

# Transcript Cleaner

Clean English Tactiq transcript exports by correcting speech-to-text misrecognitions while preserving every statement the speakers actually made. Designed for Claude Code CLI — reads and writes files directly.

## Examples

### Example 1: Standard cleaning, project named, no review items

User: "Clean meeting-2026-04-22.md, it's the ExampleApp project."

Actions:
1. Load all glossaries (general, tech, company, plus the selected project file).
2. Run pipeline. All corrections are Tier 1 (glossary matches) plus a few category-1 auto-applies. No category 2/3/4 items.
3. Write `meeting-2026-04-22-cleaned.md` next to the source.
4. Report: file path + counts + any proposed glossary additions. No `open-questions.md` is written this session (nothing to review).

### Example 2: Project auto-detected

User: "Can you clean this transcript?"

Actions:
1. Read the transcript header (first ~20 lines) to extract participant names and meeting title.
2. Match against existing files in `projects/`. Jane Doe detected; Felix and Frank in participant list → clear match.
3. Ask: *"This looks like ExampleApp (Jane Doe detected, Felix and Frank in participant list). Use that glossary? (yes / no / pick different)"*
4. Wait for confirmation, then proceed.

## Scope and limitations

**In scope**: English-language Tactiq exports in `.md` or `.txt` format.

**Out of scope** (refuse with a clear message):
- Non-English transcripts (including German)
- Non-Tactiq transcript formats (Teams, Zoom, Otter, etc.)
- Audio files
- Summarization, paraphrasing, or any output transformation other than cleaning

**Known limitations**:
- No cross-session memory. Project identification runs fresh each session.
- Glossary additions require user approval via `glossary-additions-pending.md`.
- Speaker attribution depends on Tactiq's header accuracy.
- Past meeting context is optional and user-confirmed at session start.

For known weak points and full edge case handling, load `references/edge-cases.md`.

## Hard rules (never violate)

These override all user requests. For full explanations, load `references/hard-rules.md`.

1. Clean only, never summarize
2. Never introduce content not in the transcript
3. Never reassign a statement across speakers
4. Leave spoken-language artifacts alone
5. Never guess on ambiguous corrections
6. Never delete content
7. Never reorder content
8. Never combine two speakers' statements into one line
9. Never translate
10. Never normalize spoken numbers
11. Never expand abbreviations or acronyms unless in glossary
12. Never correct grammar
13. Never infer meaning from silence or trailing sentences

## What to preserve vs. what to clean

**Always preserve (never touch)**:
- Meaning, factual claims, decisions, action items
- Statement order and speaker attribution
- All distinct utterances (if repeated, keep repetitions)
- Numbers, dates, quantities, currencies, percentages — see dedicated section below
- Timestamps when present

**May clean (the core job)**:
- Misrecognized words that exactly match a loaded glossary variant (Tier 1)
- Misrecognized words where direct evidence supports a correction (category 1 if low risk + strong evidence; category 2 — staged for user confirmation — otherwise)
- Misspelled proper names when the correct spelling is in a loaded people glossary
- Obvious speech-to-text noise (e.g. "uhhhhh" rendered as a word rather than a pause)

**Never clean without explicit user request**:
- Filler words and hesitations
- Repetitions where the speaker restarted
- Broken-but-understandable grammar
- Anything that changes meaning, emphasis, or attribution

## Numbers, dates, and quantities

Speech-to-text errors in numbers are high-risk — a wrong digit can change a commitment, a budget, or a deadline.

**Never correct a number or date based on context inference.** Leave whatever was transcribed. "Fifteen" stays "fifteen" — do not convert to "15" or infer "fifty" based on context. Spoken form is preserved exactly ("15K", "Q3", "about fifty", "five to ten").

**Only correct when** a loaded glossary contains an exact variant-to-correct mapping for that specific misrecognition (rare). When a number looks wrong but isn't glossary-covered, log as category 4. Do not guess.

## Input format

Tactiq exports follow this structure:

```
# <Meeting Title>

  Meeting started: <date>, <time>
  Duration: <N> minutes
  Participants: <name>, <name>, ...

  [View original transcript](<url>)

    ## Highlights

    > MM:SS Speaker Name: <excerpt>

  ## Transcript

  MM:SS Speaker Name: <line>
MM:SS Speaker Name: <line>
...
```

- Timestamps are `MM:SS` for meetings under an hour, `HH:MM:SS` for longer.
- The header, Highlights, and first Transcript line are indented two spaces — normalize to flush-left in output.
- The **Participants list in the header is the source of truth** for who could possibly be speaking. Lines attributed to someone not in the header → flag in correction log; do not silently reassign (hard rule 3).
- The **Highlights section** is a useful description source for auto-proposed glossary additions.

If the file does not match this structure, refuse: *"This file doesn't look like a Tactiq English export. I can only clean English Tactiq transcripts right now."*

## Language check

Detect language by sampling: first ~50 lines, midpoint ~30 lines, end ~30 lines. If ANY chunk is clearly non-English or shows substantial mixing, refuse:

*"This transcript appears to contain [language] content (detected at [start/middle/end]). I can only clean fully-English transcripts right now."*

Do not attempt partial cleaning. Refuse outright.

## Project identification

Project identification is a **pre-check** that runs before any other session-start step. Read only the transcript header (first ~20 lines) and match participant names and meeting title against existing files under `projects/`. Ignore `projects/_template.md` — it is a copy-me example, not a real project.

### Pre-check flow

**Case 2a — One clear match:**
> This looks like ExampleApp (Jane Doe detected, Felix and Frank in participant list). Use that glossary? (yes / no / pick different)

**Case 2b — Multiple possible matches:**
> This could be ExampleApp or Phoenix based on participants. Which project is this for?
> 1. ExampleApp   2. Phoenix   3. None of these

**Case 2c — No match found:**
> I don't recognise this project. A few quick questions:
> 1. What is the client name?   2. What is the project name?   3. Are these the right participants? (yes / edit)

When case 2c is confirmed, create `projects/<project-name>.md` with header metadata, `## People` populated from the confirmed participant list, and empty `## Terms`. Always wait for user confirmation. Never silently pick a project.

### Vocabulary seeding prompt (new projects only)

When a new project file was just created (case 2c only), ask once at session-start step 3:

> Project file created. Want to add any expected vocabulary before I start cleaning? Paste a list of terms, or skip. (terms / skip — default)

If the user pastes terms, add them as pre-seeded entries to `## Terms`. This prompt only appears on first project creation, never on subsequent runs.

## Project file format

Each project file (`projects/<project-name>.md`) uses the following structure:

```markdown
# ExampleApp
client: Jane Doe

## People
Jain, Jayne, Janey → Jane Doe
  Role: Client, main stakeholder

Feelix, Felix S. → Felix Example
  Role: Developer

## Terms
Example App, Exempel App → ExampleApp
  Description: Booking and reservation system

Fiscally, Fiscalator → Fiskaly
  Description: Fiscal compliance software
```

`## People` drives speaker-label matching; `## Terms` drives glossary correction matching. Both use the same arrow format as global glossary files.

### extends: mechanism (read-only)

If a project file contains `extends: shared/<client>.md` in its frontmatter, the skill also loads `projects/shared/<client>.md`. The skill reads and loads `extends:` references. It does NOT automatically create shared files. The `extends:` key is purely a load directive — the skill is read-only with respect to shared files.

### Pre-seeded vocabulary

Entries without a `→` arrow are pre-seeded terms with no known variants yet. During cleaning, the skill checks phonetic similarity against pre-seeded terms (Source B). When a correction is confirmed, the new variant is appended to that entry:

```
Before: grid view
After:  great view → grid view
```

## Glossary loading

Four scopes, loaded in priority order. Always load the three global files. Load the project file if a project was identified.

| Scope | File(s) | Always loads? |
|---|---|---|
| Project | `projects/<project-name>.md` (+ shared file if `extends:`) | Only if project selected |
| Company | `glossary-company.md` | Always |
| Tech | `glossary-tech.md` | Always |
| General | `glossary-general.md` | Always |

**Loading order**: 1) general, 2) tech, 3) company. Then if project: 4) project file, 5) shared file if `extends:` present. Missing files: continue without error.

For entry format and Tech vs. General decision rule, see `references/glossary-format.md`. **Load lazily** — only at step 12 or when processing GA decisions.

**Conflict precedence** (most specific wins): Project > Company > Tech > General. Same-level conflict → log to `open-questions.md`, let user resolve.

**Cross-project person resolution**: Company colleagues resolve from `glossary-company.md` automatically — it always loads.

## Conversational add command

At any time: "Add grid view and Bluetooth to ExampleApp glossary", "Add Jane to the ExampleApp people", etc.

**Trigger**: any sentence with "add [something] to [project]" referring to enriching a project file.

**Behavior**: open the project file, identify the section (`## People` for persons, `## Terms` for vocabulary), add in pre-seeded format, confirm: *"Added 'grid view' and 'Bluetooth' to ExampleApp → `projects/exampleapp.md` (## Terms)."*

If no project is active, ask which project before writing.

## Past meeting context

Past cleaned transcripts in the source folder provide background context but are NOT precedent. **Glossaries are the source of truth.**

At the start of every cleaning session, check for `<...>-cleaned.md` files in the source folder. If found, ask once:

> Found N cleaned transcripts in this folder. Scan them as background context for this cleaning? (yes / skip — default)

Default is **skip**. If no cleaned transcripts exist, skip the prompt silently. A term left uncorrected in a past transcript does NOT automatically stay uncorrected if the glossary now covers it.

## Working folder reference materials

When the source folder contains other files (notes, agendas, slide decks), ask once:

> *"I see attachments in this folder: notes-frank.md, agenda.md. Are any of these your own notes from the meeting (authoritative — can correct factual errors)? The rest will be used as reference material (word-level disambiguation only)."*

**Authoritative** (user-marked): can correct factual errors. **Reference** (default): word-level disambiguation only. If user doesn't respond, everything defaults to reference. Reference material may NOT add content (hard rule 2). Files only — no Notion, no email.

## Cleaning pipeline

Execute in order. Runs end-to-end without pausing — items needing review are written to `open-questions.md` for asynchronous review.

### Session-start sequence (must complete before pipeline step 1)

1. **Project pre-check** — read transcript header (~20 lines), match against `projects/`, confirm or create project file. Load glossaries immediately after.
2. **Past meeting context** — if cleaned transcripts exist, ask once: *"Found N cleaned transcripts. Scan as context? (yes / skip — default)."*
3. **Vocabulary seeding** — ONLY if a new project file was just created: ask once what vocabulary to pre-seed. Skip for existing projects.
4. **Working folder reference materials** — ask once which files (if any) are authoritative.

Then run step 0, followed by steps 1+. Skip steps that don't apply (e.g., no source folder context).

### Output categories

Every phrase is classified into exactly ONE of four categories:

- **Category 1 — Auto-applied.** Direct evidence + Low risk + Strong evidence. Applied silently, logged under "Tier 2 — Auto-applied". No OQ ID.
- **Category 2 — Staged candidate.** Direct evidence exists but risk gate failed (any High-risk axis, or Moderate/Weak evidence). Written to `open-questions.md`. Transcript NOT modified until approved.
- **Category 3 — Review-only hypothesis.** Context signals only, no direct evidence. Written to `open-questions.md` with "no direct evidence" label. NEVER auto-applied.
- **Category 4 — Unclear.** No candidate, no supported hypothesis. Left as-is. Written to `open-questions.md`. Sub-label by relevance score: 3+ → "Unknown — likely project-relevant"; 0–2 → "Unclear, no candidate."

**Legacy labels in correction log**: Tier 1 = exact glossary match; Tier 2-Auto = category 1; Tier 2-Review = categories 2 and 3; Tier 3 = category 4.

### Candidate generation

A correction candidate requires at least one direct evidence source (A–D or I). Sources F or G alone qualify for category 3 only.

**Evidence sources**: **A** = glossary near-miss (case/punctuation/whitespace); **B** = phonetic similarity to glossary/project term; **C** = supporting material + phonetic/contextual link; **D** = in-transcript recurrence with established correction; **E** = sentence context combined with A–D (context alone is NOT Source E); **F** = past meeting context (category 3 only, never 1 or 2); **G** = domain pattern match (weak; alone qualifies for category 3 only); **I** = cross-document: term correct in Highlights but mangled in Transcript. (H intentionally skipped.)

**Category 3 conditions**: no A–E required, but only when (1) phrase is clearly STT noise, (2) context strongly suggests a specific term, AND (3) Claude can articulate at least 2 distinct contextual signals. Fewer than 2 signals → category 4 instead.

**Category 4 conditions**: suspicious phrase, no direct evidence, no strongly-supported hypothesis. Record phrase, brief context, any rejected weak hypotheses.

**Recurrence bundling**: when multiple variants map to the same correct form, create a single OQ entry (grouping key = proposed correct form). Format: `[OQ-NNN] "CorrectForm" — N occurrences, M variants | First/Last seen: timestamps`. One decision applies to all. Category 1 bundles: single aggregate line in correction log.

**Critical separations**: category 3 NEVER auto-applied (risk gate bypassed entirely for hypotheses). High-risk tokens (names, numbers, dates, modals, negations, Highlights content, speaker labels) NEVER auto-applied. Evidence confidence and risk are independent axes — auto-apply requires Low risk AND Strong evidence AND A/B/C/D/I.

### Pipeline steps

0. **Bookend detection**: Mark pre-meeting joining phrases and post-meeting sign-off lines at the Transcript start/end. Apply Tier 1 only — no category 2/3/4 classification on bookend sections. Log: `Pre-meeting section (lines N–M): Tier 1 only.`

1. **Parse** into header, Highlights, Transcript sections. Keep original file untouched.
2. **Normalize whitespace** — strip two-space indentation artifact from header, Highlights, and first transcript line.
3. **Apply Tier 1 fixes** (silent): exact variant matches from all loaded glossaries. Case-insensitive; preserve natural casing in output. Track counts.
4. **Classify each suspicious phrase** (not caught by Tier 1) into one of the four output categories:
   - Direct evidence (A–D/I) → correction candidate. Record: proposed correction, evidence source + confidence qualifier (Strong/Moderate/Weak), risk classification, relevance score, 2–3 sentence context summary, linked OQ partners (if same sentence). Risk gate: all conditions hold → category 1; any fail → category 2.
   - Context-only (2+ signals, no A–D/I) → category 3 hypothesis. Record signals and context summary. Risk noted but does NOT gate — no auto-apply path for hypotheses.
   - No candidate, no supported hypothesis → category 4. Record phrase, context summary, any rejected hypotheses. Relevance score determines sub-label.
   - **Bias rule**: borderline 1 vs 2 → prefer 2; 2 vs 3 → prefer 3; 3 vs 4 → prefer 4.
5. *(merged into step 4)*
6. *(merged into step 4)*
7. **Speaker identification**: match anonymous labels ("Speaker 1") using direct name mentions, participant list, and people glossaries. Confident match → `Speaker 1 (Alex)`. Uncertain → leave as `Speaker 1`, note in correction log. Speaker labels are always High-risk — never reach category 1.
8. **Apply category 1 fixes** (silent): apply corrections. Log summary header: `X silent fixes — Y unique corrections applied`. Full list in compact appendix at end of correction log (bundled format when variants share a correct form).
9. **Verify integrity**: count timestamped lines in output vs. original. Mismatch → do NOT write the cleaned file; stop and report the discrepancy.
10. **Assign IDs** to all category 2, 3, and 4 items and to proposed glossary additions (see "ID assignment"). Category 1 items get no OQ IDs.
11. **Write cleaned file** to `<original-basename>-cleaned.md`. Category 2/3/4 items carry `[OQ-NNN]` IDs; proposals carry `[GA-NNN]` IDs in the correction log. **Load `references/correction-log-format.md` lazily at this step** — only when writing output files (steps 11–13).
12. **Propose glossary additions**: identify misrecognitions meeting criteria (see "Glossary addition criteria"). Append to `glossary-additions-pending.md`. Flag 15+ occurrence entries as high-priority (⚠️). Do NOT write to glossary files — only after user approval.
13. **Update open-questions file**: append all category 2, 3, and 4 items to `open-questions.md`. Every entry must include: **Context** (2–3 sentence paraphrase of surrounding discussion), **Evidence confidence** (Strong/Moderate/Weak for cat 2; `Confidence: None` for cat 4; `Context signals:` for cat 3), and **Linked** field when another cat 2/3/4 entry exists in the same sentence (both entries reference each other; linked-pair pause applies at processing time).
14. **Report to user**: one-paragraph summary — output path, counts per category, itemized glossary proposals with `[GA-NNN]` IDs, pointer to `open-questions.md`. See `references/correction-log-format.md` for the exact summary template.

### Clustering rules for category 2 items in open-questions.md

Medium and Low category 2 items are grouped by primary risk reason. Canonical cluster names:

- **Common-word swap in factual context** — e.g., "share" / "chair", "graph" / "grid"
- **Domain term with multiple candidates** — e.g., "Slack channel" / "Slack page"
- **Multi-token ambiguity** — e.g., "boss booking" / "edit button"
- **Speech-to-text noise / heavy mangle**
- **Meaning-changing function word** — e.g., "turn up" / "turn off"
- **Other Medium** / **Other Low**

Create the `####` cluster heading even with only 1 item. Category 3 and 4 entries are NOT clustered — listed individually.

### Asynchronous review workflow

All items needing attention are written to `open-questions.md` — no live chat block during cleaning. The user reviews asynchronously: open the file, edit `| decision: <value>` suffixes, then ask Claude to `process OQ decisions`. Natural-language shortcuts (e.g., "approve OQ-3 and OQ-7", "set decision: keep original on all Medium-risk items") let the user bulk pre-fill before processing.

## Dry-run mode (QA)

**Triggers**: "QA dry run on <file>", "dry run <file>", "test mode on <file>". Runs the full pipeline without writing to disk. Accepts `project`, `past-meetings`, `reference-files` parameters; when omitted, reports which prompt would appear and assumes safe defaults. Block formats and refusal output: `references/dry-run.md`.

## Risk classification

Risk is assessed across three independent axes: **token category** (what kind of word), **sentence role** (what the sentence is doing), and **location** (where in the document). **Effective risk = max of all three axes.** Any High axis blocks auto-apply. The Pleasantry exception caps the combined token + sentence-role at Medium when sentence role is Pleasantry — the location axis is independent and not subject to this cap. Category 3 hypotheses bypass the gate entirely. Category 4 has no candidate, so no gate applies.

For full axis definitions, evidence confidence qualifiers, worked examples, and the auto-apply gate summary, load `references/risk-classification.md` at pipeline step 4.

## Relevance scoring

Relevance scoring adjusts effective risk before routing. Score 0–6 by summing signals A–F: sentence role type (Signal A), glossary density in the surrounding 30-second window (Signal B), proximity to Highlights (Signal C), decision-marker words like "agreed" or "confirmed" (Signal D), temporal commitments (Signal E), answer-to-question pattern (Signal F). A co-occurrence boost applies when the sentence already contains a High-risk item (not in Pleasantries). Score 3+ keeps classified risk; score 0 in a Pleasantry/aside drops risk by one level.

For full signal definitions and routing rules, load `references/relevance-scoring.md` at pipeline step 4.

## ID assignment

Every entry in `open-questions.md` and `glossary-additions-pending.md` gets a stable ID for cross-referencing. IDs also appear in the cleaned file's correction log.

### Format

- **Open questions**: `OQ-NNN` (zero-padded 3 digits). Render as `**[OQ-NNN]**` at the start of each bullet.
- **Glossary additions**: `GA-NNN` (zero-padded 3 digits). Render as `**[GA-NNN]**` at the start of each entry.
- Sequences are **scoped per file** — each `open-questions.md` and `glossary-additions-pending.md` has its own independent counter. Use 4 digits past 999.

### Assigning the next ID

1. Read the target file. If it doesn't exist, start at `OQ-001` / `GA-001`.
2. Scan for all existing `[OQ-NNN]` / `[GA-NNN]` tokens; take the maximum and add 1.
3. Assign IDs in deterministic order: timestamp order for OQ; first-occurrence order for GA.
4. Use the same IDs in the cleaned file's correction log for cross-reference.

### Stability rules

- IDs never change once assigned. Gaps are normal — never renumber to compact.
- Never reuse a retired ID. Continue from the highest ever assigned (when in doubt, jump ahead by the count of removed entries observed this session).
- Reset only on full file deletion — the next run restarts at `OQ-001` / `GA-001`.

### How the user references IDs

Accept flexible forms: `OQ-3`, `OQ-003`, `oq-3`, just `3`; lists `3, 7, 12`; ranges `1-5`; bulk `all` or `all from <filename>`. When `3` is ambiguous (both OQ-3 and GA-3 exist), ask which they meant.

## Glossary addition criteria

Propose only terms that are recurring (2+ occurrences or obviously-recurring type), clearly a misrecognition, and scope-appropriate. Real English word variants require a usage-context note or are not proposed. Flag as high-priority (⚠️) when 15+ occurrences. For full criteria, the Do-NOT-propose list, target-file selection, and the merging-vs-creating rule at approval time, load `references/glossary-format.md` at pipeline step 12.

## Decision format and review workflow

The primary way the user reviews `open-questions.md` and `glossary-additions-pending.md` is by editing a plain-language **decision suffix** on each entry, then asking Claude to process the file.

### The decision suffix

Every entry carries a decision suffix on its anchor line: `... | decision: <value>`

For OQ entries, the suffix appears at the end of the line. The entry must show the variant, proposed correction (if any), and a short why-phrase so the reviewer can decide without re-reading the transcript:

```
- [OQ-005] 12:01 Kai: "for end user to book, the greed view" — `greed` → `grid` (booking UI context) | decision: pending
```

For High-risk items, the format is richer — full prose context, a required `Description:` field, `Evidence:` (with confidence qualifier), and `Risk: High — <reason>`. See `references/correction-log-format.md`.

For GA entries, the suffix appears on the `[GA-NNN]` anchor line at the top of the multi-field block. Claude writes `| decision: pending` on all entries at append time; the user edits the value during review.

### Decision values

| Value | Meaning | Terminal? |
|---|---|---|
| `pending` | Not reviewed yet (written by Claude) | no |
| `approved` | Apply Claude's proposal | yes |
| `edit: <text>` | Apply `<text>` instead (OQ only) | yes |
| `keep original` | No change; as-transcribed is correct (OQ only) | yes |
| `drop` | No change; entry discarded | yes |
| `unsure` | Reviewed but undecided | no |

`pending` = "I haven't looked." `unsure` = "I looked, I don't know yet." Both stay; both skipped during processing. Terminal decisions are removed after processing.

For GA entries needing a tweak, edit the multi-line block's fields directly before setting `decision: approved`. `edit:` and `keep original` are OQ-only.

### Edit syntax for OQ entries

```
- **[OQ-009]** 22:00 Daniel: "dessert a bit selection" | decision: edit: chair selection
```

Constraints: may contain spaces/punctuation/apostrophes; may NOT contain `|`; may NOT span multiple lines; empty `edit:` is invalid.

### Processing trigger

Triggered by: `process OQ decisions`, `apply OQ decisions`, `process GA decisions`, `apply GA decisions`, `review pending`, or similar.

Steps:
1. **Identify target file** — OQ or GA in the source transcript's folder. If no context, ask the user.
2. If the file doesn't exist or has no entries: *"No <OQ/GA> file to process."* Stop.
3. Read the file; parse the decision suffix from each anchor line.
4. For each entry: terminal → apply effect and remove; `pending`/`unsure` → leave; invalid → leave and queue for report.
5. **Cleanup**: remove empty session headers. If no entries remain, delete the file entirely. Never renumber.
6. **Report**: `Processed <file>: A approved, E edited, K kept original, D dropped. M remain pending/unsure. V invalid: [IDs].` Omit zero categories; list invalid IDs.

   **GA extension**: after writing approved GA entries, scan all `open-questions.md` files for variants now covered by new glossary entries. Append: *"OQ items now covered by new glossary entries: [OQ-NNN] (by GA-MMM), ..."* Flagged OQ items stay at `pending` — user confirms `drop` manually.

   **Linked-pair pauses**: if an approved OQ entry's linked partner is non-terminal, pause: *"[OQ-NNN] is approved but its linked item [OQ-MMM] is still pending. Resolve [OQ-MMM] first? (yes / apply anyway)"* List skipped IDs in the report.

   **Conflict-detection blocks**: if an approved OQ entry conflicts with an existing glossary mapping, list each blocked ID and both competing forms. Wait for user resolution before applying.

### Applying terminal decisions

**OQ entries** — before applying `approved` or `edit:`, run conflict detection and linked-partner pause:
- `approved` → open cleaned file, locate line by timestamp + speaker, replace the unclear token. Append resolution note under `### Resolved post-hoc` in the correction log.
  - **Hypothesis promotion (Feature 3)**: if an approved category 3 item meets glossary criteria, ask once: *"Confirmed. Also propose '<variant> → <correct form>' for the glossary? (yes / skip)"* On `yes`: append a GA entry with `Source: confirmed hypothesis [OQ-NNN]`. Never auto-add directly to glossary files.
- `edit: <text>` → same as `approved`, using `<text>` as the correction. Same checks apply.
- `keep original` → no transcript change. Append resolution note with `resolved as-transcribed`.
- `drop` → no change, no note. Entry discarded.

If the cleaned file no longer exists, tell the user and skip the transcript update — still remove the OQ entry.

**GA entries**:
- `approved` → open target glossary file, apply merge-vs-create rule (see `references/glossary-format.md`). The `[GA-NNN]` ID is NOT written to the glossary file.
- `drop` → do not write to glossary.

#### Conflict detection on approval

A conflict exists when the variant already appears in a glossary entry mapping to a DIFFERENT correct form. On conflict, do NOT apply. Surface to user:

> "Cannot apply [OQ-NNN]: the glossary already maps '<variant>' → '<existing>', but this entry proposes '<new>'. Options: a) Keep glossary, update this OQ  b) Update glossary to new form  c) Skip for now"

#### Linked-partner pause

When an approved OQ entry's `Linked:` field points to a partner still at `pending` or `unsure`, pause:

> "[OQ-NNN] is approved but its linked item [OQ-MMM] is still pending. Resolve [OQ-MMM] first? (yes / apply anyway)"

On `apply anyway`: proceed. If both entries have terminal decisions, no pause.

#### Auto-resolve OQ when glossary now covers it (Feature 4)

After `process GA decisions` writes approved entries: scan all `open-questions.md` files in scope. For each pending entry whose variant is now covered, add inline: `[auto-flagged: now covered by glossary — review and drop if resolved]`. Decision stays `pending` — user confirms `drop` manually. Report the list.

### Invalid decision handling

- Unrecognized value → leave, add to invalid-IDs.
- `edit:` with no text or with `|` in text → leave, report invalid.
- Missing suffix entirely → treat as `pending` (backward compatibility). Not flagged invalid.

Bias: when in doubt, do not act. Report so the user can fix.

### Synonym recognition

| Canonical | Accepted synonyms |
|---|---|
| `approved` | `yes`, `ok`, `okay`, `fine`, `looks good`, `go ahead`, `approve`, `accept`, `confirmed`, `correct`, `right` |
| `keep original` | `keep`, `leave it`, `as-is`, `as is`, `no change`, `leave`, `original` |
| `drop` | `ignore`, `skip`, `remove`, `not worth`, `delete`, `dismiss` |
| `unsure` | `maybe`, `not sure`, `don't know`, `uncertain`, `?` |

`edit: <text>` has no synonyms. Claude continues to write canonical values on new entries.

### Fix invalid OQ decisions command

Triggered by: `fix invalid OQ decisions`, `fix OQ decisions`, `clean up OQ decisions`, or similar.

Read the target file, rewrite synonyms and obvious typos to canonical form, report every conversion. Never applies decisions — only normalizes. User must still run `process OQ decisions` afterward.

> Fixed `<file>`: <N> decisions converted (e.g. `yes` → `approved` on [OQ-NNN]). <M> remain invalid: [list]. Run `process OQ decisions` to apply them.

### Quick alternatives (natural-language)

- `set decision: approved on OQ-1, OQ-3, OQ-7` — Claude pre-fills; user then processes.
- `set decision: approved on all Medium-risk OQ from <session>` — bulk pre-fill.
- `OQ-7 is 'plus'` — Claude sets `decision: edit: plus` on OQ-7.
- `apply OQ-3 and OQ-7` — Claude sets `decision: approved` on both, then processes.

## Output

### Cleaned transcript file

Write to `<original-basename>-cleaned.md` in the same directory. Never overwrite an existing `-cleaned.md` without asking: *"A cleaned version already exists: `<filename>`. Overwrite? (yes/no/diff)"* If "no", offer `<basename>-cleaned-v2.md`.

For the cleaned file structure and correction log format, see `references/correction-log-format.md`.

### Open-questions file

Write to `open-questions.md` in the same folder as the source transcript. Append a new session block if the file already exists.

Within each per-session header (`## From <cleaned-filename>`), entries are organized into four subsections:
- `### Must review (High risk)` — High-risk category 2 candidates, listed individually. Always present (show `_None this session._` if empty).
- `### Optional review (Medium risk) — N items` — Medium-risk category 2 candidates, clustered by risk reason. Always present (show `_None this session._` if empty).
- `### Hypotheses for confirmation — N items` — category 3 items with explicit "no direct evidence" label. Only if any exist.
- `### Unclear (no candidate) — N items` — category 4 items. Only if any exist.

See `references/correction-log-format.md` for exact per-entry format.

### Pending glossary additions file

Write to `glossary-additions-pending.md` in the same folder. `open-questions.md` and `glossary-additions-pending.md` are independent — reviewing one does not affect the other.

### End-of-run summary

One short paragraph in chat: output path + counts per category + itemized glossary proposals with `[GA-NNN]` IDs + pointer to `open-questions.md`.

- Always show the silent-fix split (Tier 1 vs. category 1).
- Break out open-questions items by sub-category; omit zero-count sub-categories.
- If no glossary additions: omit GA block. If no category 2/3/4 items: omit OQ block.
- **High-priority callout**: if any GA entries hit 15+ occurrences, insert a `⚠️ High-priority glossary proposal: **[GA-NNN]** \`<variant> → <correct form>\` (<N> occurrences). Review soon.` line ABOVE the GA list.
- Conclude with the pointer to `open-questions.md` and `glossary-additions-pending.md` (or omit if neither was written).

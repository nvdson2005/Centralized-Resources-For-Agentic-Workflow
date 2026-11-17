# Correction Log and Output Format

Defines the structure of three files the skill produces. All three live in the same folder as the source transcript:
- The cleaned transcript file (`<original-basename>-cleaned.md`)
- The open-questions file (`open-questions.md`)
- The pending glossary additions file (`glossary-additions-pending.md`)

## Cleaned transcript file

File path: `<original-basename>-cleaned.md` in the same directory as the source.

Structure:

```markdown
# <Meeting Title>

**Meeting started:** <date>, <time>
**Duration:** <N> minutes
**Participants:** <name>, <name>, ...
**Project:** <project name, or "general" if none selected>

[View original transcript](<link from Tactiq>)

## Highlights

> MM:SS Speaker Name: <cleaned excerpt>
> MM:SS Speaker Name: <cleaned excerpt>

## Transcript

MM:SS Speaker Name: <cleaned line>
MM:SS Speaker Name: <cleaned line>
...

## Correction Log

### Tier 1 — Silent fixes (glossary matches)
- Jira (was: GIA, Gia), 8 occurrences
- Figma (was: Figmar), 2 occurrences

### Tier 2 — Auto-applied (low risk, contextual)

2 silent fixes — 2 unique corrections applied

### Category 2 — Staged correction candidates (awaiting review in `open-questions.md`)
- **[OQ-042]** **08:17 Frank:** "we're using Cortex for the surveys", token `Cortex` → candidate `Qualtrics`. Evidence: Moderate evidence — Source C (`notes-frank.md` lists Qualtrics as the survey tool). Risk: Medium.
- **[OQ-049]** **22:10 Frank:** "the book and graph view", token `graph` → candidate `grid`. Evidence: Strong evidence — Source E (UI-listing context + Source B near-match). Risk: Medium.

### Category 3 — Review-only hypotheses (no direct evidence — awaiting confirmation in `open-questions.md`)
- **[OQ-051]** **31:55 Felix:** "we need blue gold pairing for the speaker", phrase `blue gold` → hypothesis `Bluetooth` (no direct evidence). Context signals: wireless pairing discussion, speaker connection, device-settings adjustments in surrounding lines.

### Category 4 — Unclear (no candidate — surfaced in `open-questions.md`)
- **[OQ-052]** **42:08 Frank:** "draw in the business, mainly melodious best", phrase `mainly melodious best`. Considered: weak hypotheses involving "main", "metric" — none cohere with surrounding sentence. No candidate proposed.

### Speaker attribution notes
- None. (Or: "14:22 — line attributed to 'Speaker 4' but only 3 participants listed. Left as-is.")

### Glossary additions proposed this session (awaiting review in `glossary-additions-pending.md`)
- **[GA-014]** Proposed `Cordex, Cortes → Cortex` for `projects/exampleapp.md` (recurring, 4 occurrences, project-specific). Description (auto-inferred): A survey tool used for customer feedback.
- **[GA-015]** Proposed `Frank N → Frank Nguyen` for `projects/exampleapp.md`. Description (auto-inferred): Lead engineer on ExampleApp project.

### Tier 2 appendix — Silent fix detail
- deployment (was: "deploy meant" — 15:02 Frank). Risk: Low. Strong evidence — Source A (glossary entry for "deployment" variants). Reasoning: exact variant pattern in context.
- kind of working (was: "kinda working" — 18:44 Felix). Risk: Low. Strong evidence — Source A (discourse-filler rule). Reasoning: spoken contraction of "kind of".
```

### Rules for the cleaned file

- Omit any correction-log subsection that has no content. Never include empty headings.
- In **Tier 1**, collapse to one line per correct term (not per occurrence). Format: `<correct> (was: <variant1>, <variant2>), N occurrences`. No IDs — Tier 1 fixes are not user-reviewable.
- In **Tier 2 — Auto-applied (low risk, contextual)** — i.e., category 1 — the main log body shows only a summary header: `X silent fixes — Y unique corrections applied`. Individual fix lines are NOT written in the main body. The full list appears in the **Tier 2 appendix** section at the end of the correction log, one line per fix: `<correct form> (was: "<variant>" — MM:SS Speaker). Risk: <level>. <Strong|Moderate|Weak> evidence — Source <letter> (<brief reference>). Reasoning: <one phrase>.` For bundled fixes (multiple variants → same correct form), use: `<correct form> (was: <variant1> ×N, <variant2> ×N…) — N occurrences`. No IDs. Sources `E`, `F`, and `G` do NOT appear here — they cannot auto-apply.
- In **Category 2 — Staged correction candidates**, one line per item with `[OQ-NNN]` prefix matching the entry now in `open-questions.md`: timestamp, speaker, brief context, token, proposed candidate, Evidence source (with Strong/Moderate/Weak qualifier), Risk. The transcript was NOT modified for these — they await user approval in `open-questions.md`.
- In **Category 3 — Review-only hypotheses**, one line per item with `[OQ-NNN]` prefix matching the entry now in `open-questions.md`: timestamp, speaker, brief context, phrase, hypothesis, explicit "(no direct evidence)" marker, brief context-signal summary. The transcript was NOT modified.
- In **Category 4 — Unclear (no candidate)**, one line per item with `[OQ-NNN]` prefix matching the entry now in `open-questions.md`: timestamp, speaker, brief context, phrase, brief "Considered: …" line documenting which avenues Claude tried.
- The legacy subsections **"Tier 2 — Contextual fixes (user-approved on review)"** and **"Tier 2 — Demoted to Tier 3"** are NO LONGER WRITTEN. The new pipeline has no live-review step, so nothing is "approved during review" or "demoted" during the run. Cleaned files written by older versions that contain these subsections remain valid; don't rewrite them.
- Preserve original speaker labels. When matched to a real name, render as `Speaker 1 (Alex)`.
- The "Glossary additions proposed" subsection mirrors what was written to the pending file. Each line carries its `[GA-NNN]` prefix matching the entry in `glossary-additions-pending.md`. Mark descriptions as `(auto-inferred)` when applicable.
- IDs are assigned per the "ID assignment" section of `SKILL.md` and are stable across sessions. Never renumber.

## Open-questions file

File path: `open-questions.md` in the same folder as the source transcript.

Create if missing.

Append-only — never rewrite existing content. Each new cleaning session that produces category 2, 3, or 4 items appends a new section.

Structure:

```markdown
# Open Questions

Edit `decision:` values → ask Claude to `process OQ decisions`.
Values: `approved` · `edit: <text>` · `keep original` · `drop` · `unsure`

---

## From `<cleaned-filename>` (cleaned <date>)

### Must review (High risk)

---
[OQ-044] 16:02 Frank:
Transcript: "we need Alice to sign off"
Context: Frank is summarizing who needs to approve the final spec. Alex (the lead engineer) and Jane were named as approvers earlier in the meeting. There is no Alice in the participant list.
Proposal: Alice → Alex  (alt: Alexa)
Evidence: Weak evidence — Source B (phonetic near-match to participant `Alex` in the header)
Risk: High — proper name + speaker attribution concern.
| decision: pending

---
[OQ-051] 24:50 Frank:
Transcript: "we should ship by Friday"
Context: Frank is recapping the ship plan after the Wednesday demo. The agenda explicitly commits to Wednesday as the ship date; Friday would contradict that written commitment.
Proposal: Friday → Wednesday
Evidence: Moderate evidence — Source C (`agenda.md` lists Wednesday as the ship date)
Risk: High — date in commitment context.
| decision: pending

---
[OQ-058] 31:12 Felix:
Transcript: "no, I disagree with that"
Context: Felix is responding to Frank's pricing proposal. The sentence cadence (no comma pause, immediate disagreement) suggests the "no" may actually be the filler "you know" preceding the disagreement clause, which would make the literal-negation reading redundant.
Proposal: no → know  (alt: keep original `no`)
Evidence: Weak evidence — Source E (sentence cadence + Source B near-match for the bigram "you know")
Risk: High — negation token.
| decision: pending

### Optional review (Medium risk) — 7 items

#### Common-word swap in factual context — 3 items
[OQ-042] 08:17 Frank"using **Cortex** for the surveys"
Context: Discussion of which survey tool the team should standardize on.
`Cortex` → `Qualtrics` (alt: keep `Cortex`) — both plausible; surveys context.
| decision: pending

[OQ-049] 22:10 Frank"the book and **graph** view"
Context: Frank listing UI views in the booking admin panel.
`graph` → `grid` — UI listing context; "graph view" is not a panel in this app.
| decision: pending

[OQ-053] 26:40 Felix"two **guys** for the work"
Context: Felix is describing the pairing arrangement for the migration task.
`two guys` → `two guides` — work-pairing context.
| decision: pending

#### Domain term with multiple candidates — 3 items
[OQ-046] 14:55 Frank"we use the **Slack page**"
Context: Frank explaining where async updates are posted.
`Slack page` → `Slack channel` — Slack vocabulary; "page" is not a Slack noun.
| decision: pending

[OQ-047] 18:30 Felix"**cultural jump** after onboarding"
Context: Felix is mapping out where new hires find product documentation.
`cultural jump` → `Confluence space` — onboarding doc tool; phonetic mangle.
| decision: pending

[OQ-055] 28:55 Frank"the **crosswalker** for both"
Context: Frank is naming the abstraction layer between the iOS and Android stacks.
`crosswalker` → `Cross Platform` — tech stack term; weak — STT mangle.
| decision: pending

#### Speech-to-text noise / heavy mangle — 1 item
[OQ-061] 35:12 Felix"**Pyrex** questions"
Context: Felix is summarizing what onboarding interviewers ask about the codebase.
`Pyrex` → `pricing`? (alt: `prerequisites`) — weak; STT mangle.
| decision: pending

### Hypotheses for confirmation (context-based, no direct evidence) — 2 items

---
[OQ-062] 38:21 Frank:
Transcript: "we need blue gold pairing for the speaker"
Context: The team has just moved from the conference room to the smaller huddle space and is troubleshooting why the speakerphone isn't picking up audio. Frank is describing setup steps.
Hypothesis: Bluetooth — unconfirmed, no direct evidence
Context signals: wireless pairing discussion, speaker connection, device-settings adjustments in the next 3 lines.
Linked: [OQ-063] — same sentence; resolving one may affect the other.
| decision: pending

---
[OQ-063] 38:21 Frank:
Transcript: "we need blue gold pairing for the speaker"
Context: Same sentence as OQ-062. The "for the speaker" portion may itself be mangled, referring to the meeting-room speaker device.
Hypothesis: pairing → connection — unconfirmed, no direct evidence
Context signals: pairing/connection language is interchangeable in the surrounding three lines.
Linked: [OQ-062] — same sentence; resolving one may affect the other.
| decision: pending

### Unclear (no candidate) — 3 items

---
[OQ-064] 45:30 Frank:
Transcript: "do able to squid the payment"
Context: Frank is asking whether the new admin UI lets staff cancel a transaction after capture. The audio around this phrase is very garbled.
Unclear: phrase `squid` — no candidate could be formed.
Considered: void / skip / process — audio too garbled to disambiguate.
Confidence: None
| decision: pending

---
[OQ-065] 47:15 Felix:
Transcript: "the frame cancel and of the editing action"
Context: Felix is describing a UI sequence in the booking flow. The surrounding sentences are coherent but this phrase reads as a heavy STT mangle.
Unclear: phrase `frame cancel and of` — no candidate could be formed.
Considered: no candidate (no plausible interpretation).
Confidence: None
| decision: pending

---
[OQ-066] 49:02 Frank:
Transcript: "we draw in the business, mainly melodious best"
Context: Frank is closing the meeting with a high-level summary of the team's revenue strategy.
Unclear: phrase `mainly melodious best` — no candidate could be formed.
Considered: weak hypotheses involving "main", "metric" — none cohere with surrounding sentence.
Confidence: None
| decision: pending

---

## From `<another-cleaned-filename>` (cleaned <date>)

### Must review (High risk)

_None this session._

### Optional review (Medium risk) — 1 item

#### Meaning-changing function word — 1 item
[OQ-067] 12:08 Felix"we interrupted by **turn up** Bluetooth"
Context: Felix is describing how a device handoff was interrupted mid-call.
`turn up` → `turn off` — interruption context; "turn up" is meaning-changing.
| decision: pending
```

### Rules for open-questions.md

#### Per-session structure

Each `## From <cleaned-filename> (cleaned <date>)` session block contains the following subsections **in this order**:

1. `### Must review (High risk)` — **always present** (show `_None this session._` if empty). High-risk category 2 items only. Individual full-detail lines.
2. `### Optional review (Medium risk) — N items` — **always present** (show `_None this session._` if empty). Medium-risk category 2 items, grouped under `#### <cluster name> — <count> items` headings. Compact lines. N is the sum across clusters.
3. `### Hypotheses for confirmation (context-based, no direct evidence) — N items` — **only present if any category 3 items exist**. Individual full-detail lines. Omit the entire subsection otherwise.
4. `### Unclear (no candidate) — N items` — **only present if any category 4 items exist**. Individual full-detail lines. Omit the entire subsection otherwise.

The legacy three-subsection structure (Must review / Optional review / Low risk rare) is REPLACED by the four-subsection structure above. Low-risk category 2 items that reach `open-questions.md` (rare under the new pipeline — most Low-risk evidence-based candidates become category 1) live under "Optional review (Medium risk)" with cluster name `Other Low`. There is no separate Low-risk subsection.

#### Mixed-format files

Existing `open-questions.md` files written by older versions of this skill may use any of three earlier formats:
1. The three-subsection format (Must review / Optional review / Low risk rare) without category 3 or 4 splits.
2. The four-subsection format with single-line High / Hypothesis / Unclear entries (no `---` separators, `Description:` field instead of `Context:`, no inline `Confidence:` on Medium).
3. Any partial intermediate (e.g., four-subsection but with Description rather than Context).

**Do not retroactively reformat existing session blocks during a normal cleaning run** — leave old sessions in their original format. New session blocks appended to an existing file use the current multi-line block format with `---` separators, mandatory `Context:` field (and `Confidence: None` for Category 4 entries), and optional `Linked:` field. Mixed-format files are acceptable.

The user can request a one-shot reformat ("reformat open-questions to the latest format") to migrate older session blocks. When doing this, preserve every existing ID, timestamp, speaker label, proposal, decision value, and evidence reference. Add `Context: [not available — reformat only]` when the original entry's context cannot be recovered. Never lose or merge entries.

#### Sort order

Within the file, items are sorted by:
1. **Section** — Must review High → Optional review Medium → Hypotheses → Unclear (enforced by the subsection structure).
2. **Cluster** within Medium-risk section.
3. **Timestamp ascending** within High, within each cluster, within Hypotheses, and within Unclear.

#### Item format — High-risk category 2 (Must review)

Multi-line block. Each High-risk entry is preceded by a `---` visual separator on its own line. The block lists fields one per line in this order:

```
---
[OQ-NNN] MM:SS Speaker:
Transcript: "<exact flagged phrase as it appears in the source transcript>"
Context: <2–3 sentence paraphrased summary of the ~30 seconds of surrounding discussion — who was speaking, what topic was active, what was just established>
Proposal: <variant> → <correct form>  (alt: <other>, if any)
Evidence: <Strong|Moderate|Weak> evidence — Source <A/B/C/D/E/F/G/I> (<one-line description of the specific glossary entry / material reference / Highlights line / past-meeting context that supports the candidate>)
Risk: High — <specific reason, e.g., proper name of a person; date in commitment context; modal verb in decision sentence>
Linked: [OQ-MMM] — same sentence; resolving one may affect the other.   ← only if applicable
| decision: pending
```

**Required fields**: `Transcript`, `Context`, `Proposal` (may be omitted if the entry is a flagged concern with no specific candidate — e.g., a speaker-attribution flag), `Evidence` (with confidence qualifier), `Risk`, decision suffix. **Optional field**: `Linked` (only when another category 2/3/4 entry exists in the same sentence — see Feature 5 in `SKILL.md`).

**Context field — required on every High-risk entry.** A 2–3 sentence paraphrased summary of the ~30 seconds of discussion around the flagged phrase. It must include: who was speaking, what topic was active, what was just established. It is NOT a raw transcript dump — it is a paraphrased note for someone who missed that moment of the meeting. The Context field serves both audiences: a human reviewer deciding days later without reopening the transcript, and a future AI scanning the file to verify the decision before applying it. If context cannot be determined, write `Context: [not available]`.

**Distinct from `Evidence`:** Evidence cites *what supports* the candidate (a source letter and the specific reference). Context describes *what was happening in the meeting* around the flagged phrase. Both are required.

#### Item format — Medium-risk category 2 (Optional review, clustered)

Medium-risk items appear under `#### <cluster name> — <count> items` sub-headings. **No `---` separator** between Medium-risk entries — only the cluster heading separates them visually.

Compact multi-line block:

```
[OQ-NNN] MM:SS Speaker
"<brief transcript context with flagged phrase bolded>"
Context: <one sentence — what topic was active>
<variant> → <proposal> — <reason in 5–10 words>
| decision: pending
```

**Variations**:

- **Multiple plausible candidates** — best guess first, alternative inline:
  `<variant> → <proposal> (alt: <other>) — <reason>`
- **Weak proposal** — mark with `?` on the proposal:
  `<variant> → <weak proposal>? (alt: <other>) — weak; <short reason>`

**Field meanings**:
- `<brief context>` — ~5–15 words around the unclear token, with the flagged phrase rendered in **bold** so a scanning reviewer can locate it instantly. Not the full sentence; just enough to anchor.
- `Context:` — one sentence describing what was being discussed. Shorter than the 2–3 sentence Context block used on High-risk and Hypothesis entries.
- `<variant>` — the exact token(s) as they appear in the transcript. Use backticks. For multi-token mangles, quote the whole mangled span.
- `<proposal>` — Claude's best guess at the intended word(s). Use backticks.
- `<reason>` — one phrase explaining why the proposal fits. Typical patterns: domain context cue ("booking UI context"), tool category ("documentation tool"), semantic fit ("interruption context"), or grammatical role ("sentence opener"). Five to ten words is typical; never a full sentence.

**Differences from the High format**:
- No `---` separator before each entry.
- No bold around the `[OQ-NNN]` ID (visual hierarchy: bold-and-separator for High / Hypothesis / Unclear items, plain for compact Medium items).
- No bold around the speaker name.
- No standalone Confidence field — evidence strength is implied by the reason phrase and any `?` marker on weak proposals.
- Context is shorter (one sentence instead of 2–3).
- **No `Risk:` or `Evidence:` field** — the cluster heading implies risk; evidence is summarized inline in the reason phrase.
- Decision suffix still required.

#### Item format — Category 3 (Hypotheses for confirmation)

Multi-line block preceded by a `---` separator. The phrase **"unconfirmed, no direct evidence"** appears verbatim on the Hypothesis line and is mandatory — it is the visual signal that this is a category 3 item.

```
---
[OQ-NNN] MM:SS Speaker:
Transcript: "<exact flagged phrase>"
Context: <2–3 sentence paraphrased summary of the ~30 seconds of surrounding discussion>
Hypothesis: <proposed term> — unconfirmed, no direct evidence
Context signals: <one sentence describing the specific contextual signals that support this hypothesis>
Linked: [OQ-MMM] — same sentence; resolving one may affect the other.   ← only if applicable
| decision: pending
```

**Required elements**:
- The exact phrase **"unconfirmed, no direct evidence"** must appear verbatim on the `Hypothesis:` line. It must not be omitted or softened.
- `Context signals:` must be a real, specific summary of what cues informed the guess (e.g., "wireless pairing discussion, speaker connection, device settings"). Not a generic "context suggests" handwave.
- `Context:` is mandatory (Feature 1) — the same 2–3 sentence paraphrased meeting summary required on every OQ entry. Distinct from `Context signals:` — Context describes *what was happening in the meeting*; Context signals describe *which signals support the hypothesis*.
- **No `Confidence:` field** — there is no Evidence line to qualify. The `Context signals:` field conveys the basis for the hypothesis.
- **No `Risk:` field** — risk is not surfaced for category 3 because it does not gate anything. Including it would invite the reader to weigh a hypothesis as if it were evidence-based, which it isn't.
- **No `Evidence: Source X` line** — that's the whole point of the label.
- `Linked:` is optional, included only when another category 2/3/4 entry exists in the same sentence (see Feature 5 in `SKILL.md`).

#### Item format — Category 4 (Unclear, no candidate)

Multi-line block preceded by a `---` separator. No proposal; the entry exists so the reader knows Claude flagged the phrase, attempted to resolve it, and rejected the avenues:

```
---
[OQ-NNN] MM:SS Speaker:
Transcript: "<exact flagged phrase>"
Context: <2–3 sentence paraphrased summary of the ~30 seconds of surrounding discussion>
Unclear: phrase `<variant>` — no candidate could be formed.         ← relevance score 0–2
Unknown: phrase `<variant>` — likely project-relevant, please clarify.   ← relevance score 3+
Considered: <weak hypotheses considered but rejected, or "no candidate (<short reason>)">
Confidence: None
Linked: [OQ-MMM] — same sentence.   ← only if applicable
| decision: pending
```

**Required elements**:
- The variant token in back-ticks.
- Use `Unclear:` (score 0–2) or `Unknown:` (score 3+) based on the relevance score computed during classification. Both indicate no candidate was formed.
- `Context:` (Feature 1) is mandatory — the 2–3 sentence paraphrased meeting summary required on every OQ entry.
- `Considered:` summary listing the avenues tried (so the reviewer knows the problem was attacked, not missed). If literally no avenue produced a candidate, write `Considered: no candidate (<short reason>)`.
- `Confidence: None` is mandatory and is the categorical signal that no candidate confident enough to propose was found.
- **No `Proposal:` line.** No `Context signals:` line. No `Evidence:` line. No `Risk:` line.
- `Linked:` is optional (Feature 5 — only when another category 2/3/4 entry exists in the same sentence).

#### Linked: field (Feature 5 — applies to High / Hypothesis / Unclear; optional on Medium)

When two or more category 2/3/4 entries are generated from the same sentence, they must be linked to each other in the file.

**Same-sentence detection.** Two entries qualify as linked if either of these holds:
- Their timestamps are within 2 seconds of each other AND they share a speaker label (or both are unattributed); OR
- One entry's transcript phrase appears within the other's transcript phrase (content overlap).

**Field format.** Appears on its own line on High-risk, Hypothesis, and Unclear entries (between the entry's other fields and the decision suffix):

```
Linked: [OQ-MMM] — same sentence; resolving one may affect the other.
```

On compact Medium-risk entries, the Linked: field is rare (Medium items are clustered and processed in bulk) but when needed it appears on its own line just before the decision suffix.

**Symmetry rule.** Both entries in a linked pair must carry the `Linked:` field pointing to each other. If A links to B, B must link to A. When three or more entries share a sentence, every entry lists every other member of the cluster on its `Linked:` line (comma-separated).

**Processing behavior.** When `process OQ decisions` encounters an entry with a `Linked:` field and its linked partner has a non-terminal decision (`pending` or `unsure`), Claude pauses and asks the user before applying. See "Linked-partner pause (Feature 5)" in `SKILL.md`.

#### Bundled entry format (for recurrence-bundled items)

When multiple transcript lines contain different variants that all map to the same proposed correct form, they are bundled into a single OQ entry. The grouping key is the correct form, not the variant text.

```
[OQ-NNN] "Jane" — 6 occurrences, 4 variants
         Ben Ha (×3) | Ben Hart (×1) | Ben Harp (×1) | Bernhart (×1)
         First seen: 02:14 | Last seen: 41:03
         One decision applies to all instances | decision: pending
```

Rules:
- The header uses the correct form (quoted) as the label.
- Variants are listed with per-variant counts separated by `|`.
- `First seen` and `Last seen` are the timestamps of the first and last occurrence across all variants.
- One decision applies to all occurrences in the bundle.
- The standard section placement (High / Medium / Hypothesis / Unclear) is determined by the highest-risk variant in the bundle.
- For bundled Category 1 fixes, the correction log appendix shows: `<correct form> (was: <variant1> ×N, <variant2> ×N…) — N occurrences`

#### Cluster names (for Medium-risk category 2)

Use the canonical cluster names from the "Clustering rules" section of `SKILL.md`:

- `Common-word swap in factual context`
- `Domain term with multiple candidates`
- `Multi-token ambiguity`
- `Speech-to-text noise / heavy mangle`
- `Meaning-changing function word`
- `Other Medium` / `Other Low` (catch-alls)

If a cluster has only 1 item, still create the `####` heading.

Note: Under the new pipeline, the "Speech-to-text noise / heavy mangle" cluster contains Medium-risk category 2 items only (i.e., items where Claude has direct evidence for a candidate but the surrounding STT is noisy). True no-candidate items are now in the dedicated `### Unclear (no candidate)` section — they no longer fold into this cluster.

#### Other rules (unchanged)

- Each entry begins with `[OQ-NNN]` (zero-padded 3 digits). The same ID appears in the cleaned file's correction log.
- The decision suffix at the end of every anchor line is required at write-time (`| decision: pending`). The user edits this value (`approved`, `edit: <text>`, `keep original`, `drop`, `unsure`) and asks Claude to `process OQ decisions`. See "Decision format and review workflow" in `SKILL.md`.
- IDs are assigned per the "ID assignment" section of `SKILL.md`: continue from max+1 across the entire file, not per session. **Never renumber** — gaps are normal after resolutions.
- Group by source file. Add a horizontal rule (`---`) between sessions.
- Include cleaning date so the user knows how old an unresolved item is.
- Do not deduplicate across files — the same ambiguity in two transcripts is still two observations and gets two IDs.
- If the file doesn't exist, create it with the header preamble before appending. The first ID in a fresh file is `OQ-001`.
- **When all entries have been resolved and the file would otherwise contain only the header preamble, delete the file entirely.** An empty `open-questions.md` is more confusing than no file at all — it suggests there is still something open. The file is recreated automatically the next time a cleaning run produces a category 2/3/4 item, restarting at `OQ-001`.

## Pending glossary additions file

File path: `glossary-additions-pending.md` in the same folder as the source transcript.

Create if missing.

Append-only during cleaning — never rewrite existing entries. Each cleaning session that produces glossary proposals appends a new section. Entries are removed only at approval time.

Structure:

```markdown
# Glossary Additions — Pending Review

Edit `decision:` values → ask Claude to `process GA decisions`.
Values: `approved` · `drop` · `pending` · `unsure`

---

## From `meeting-2026-04-22-cleaned.md` (cleaned 2026-04-22)

- ⚠️ **[GA-013]** | decision: pending
  **Priority**: HIGH — appeared 20 times in this transcript. Review promptly to avoid accumulating errors in future runs.
  **Variant(s)**: `cache`
  **Correct form**: `cash`
  **Target file**: `glossary-general.md`
  **Suggested category**: Business & Roles
  **Reason**: appeared 20 times; clearly STT noise (speaker consistently pronounces "cash" as `cache`); cross-project common-word swap
  **Description**: [auto-inferred — please verify] Payment-method noun, used when contrasting card and cash transactions.
  **First seen**: 03:42 "we processed about 8k in cache yesterday"
  **Occurrences in transcript**: 20
  **Note**: (none)

- **[GA-014]** | decision: pending
  **Variant(s)**: `Cordex, Cortes`
  **Correct form**: `Cortex`
  **Target file**: `projects/exampleapp.md`
  **Suggested category**: Tools & Platforms
  **Reason**: appeared 4 times; clearly STT noise; project-specific tool
  **Description**: [auto-inferred — please verify] A survey tool used by ExampleApp for customer feedback collection.
  **Note**: (none)

- **[GA-015]** | decision: pending
  **Variant(s)**: `Frank N`
  **Correct form**: `Frank Nguyen`
  **Target file**: `projects/exampleapp.md`
  **Suggested category**: Engineering
  **Reason**: appeared 7 times; participant in this meeting; project-specific person
  **Description**: [auto-inferred — please verify] Lead engineer on the ExampleApp project.
  **Note**: (none)

---

## From `meeting-2026-04-23-cleaned.md` (cleaned 2026-04-23)

- **[GA-016]** | decision: pending
  **Variant(s)**: `stride terminal`
  **Correct form**: `Stripe Terminal`
  **Target file**: `glossary-tech.md`
  **Suggested category**: Tools & Platforms
  **Reason**: appeared 2 times; recurring tool name; cross-client
  **Description**: [auto-inferred — please verify] Stripe's card-reader hardware for in-person payments.
  **Note**: (none)
```

### Rules for the pending file

- One entry per proposed addition. **Anchor line** is `- **[GA-NNN]** | decision: pending`; the seven fields follow indented: Variant(s), Correct form, Target file, Suggested category, Reason, Description, Note.
- The **decision suffix** lives on the anchor line. Valid values: `pending` (default), `approved`, `drop`, `unsure`. `edit:` and `keep original` are NOT valid for GA — to tweak a GA entry, edit its field lines directly in the file before setting `decision: approved`. See "Decision format and review workflow" in `SKILL.md`.
- IDs are assigned per the "ID assignment" section of `SKILL.md`: continue from max+1 across the entire file, not per session. **Never renumber** — gaps are normal after applies/rejections.
- **High-priority entries (Feature 7).** When the variant appeared **15 or more times** in the source transcript, the anchor line becomes `- ⚠️ **[GA-NNN]** | decision: pending` and the entry adds three fields:
  - `**Priority**: HIGH — appeared <N> times in this transcript. Review promptly to avoid accumulating errors in future runs.` — appears immediately after the anchor, before all other fields.
  - `**First seen**: <MM:SS> "<short phrase>"` — the timestamp and a short phrase of the first occurrence.
  - `**Occurrences in transcript**: <N>` — the exact count.

  All standard fields (Variant(s), Correct form, Target file, Suggested category, Reason, Description, Note) still apply. The end-of-run summary in chat surfaces high-priority entries explicitly so the user can act before review-debt accumulates. Below the 15-occurrence threshold, the normal entry format applies (no ⚠️, no Priority line, no First seen / Occurrences fields).
- **Description is required** and marked `[auto-inferred — please verify]` when generated by Claude during cleaning. Sources for the description (priority order): Tactiq Highlights → surrounding transcript context → working folder reference materials → past meetings.
- Group by source cleaned-file. Add a horizontal rule (`---`) between sessions.
- Variant(s) are comma-separated if multiple variants of the same correct form were observed.
- Target file is a relative path from the skill root, exactly as the entry will be written upon approval.
- Suggested category is the `##` heading the entry will live under in the target file.
- Reason is a short justification (occurrences observed, scope rationale).
- Note is the parenthetical that follows the variants when written, or `(none)` if no note. (Notes are mostly used for context-dependent triggers like "Adam (in list context)".)
- When all entries from a session are processed (applied or rejected), remove the session heading and trailing `---`. The remaining entries' IDs do not change.
- **When the file has no remaining entries, delete the file entirely.** An empty `glossary-additions-pending.md` is more confusing than no file at all — it suggests there is still something to review. The file is recreated automatically the next time a cleaning run proposes a new entry, restarting at `GA-001`.
- IDs are not written into the destination glossary files at apply time — they only live in the pending file.

## End-of-run summary (in chat, not file)

Keep it to one paragraph. Template:

> Cleaned `<filename>` → `<output-filename>`. <T> silent fixes (<T1> Tier 1 glossary matches, <A> category 1 auto-applies). <Q> items written to `open-questions.md` for review:
> - <H> high-risk category 2 candidates
> - <M> medium-risk category 2 candidates
> - <P> category 3 hypotheses (no direct evidence)
> - <U> category 4 (no candidate)
>
> ⚠️ High-priority glossary proposal: **[GA-NNN]** `<variant> → <correct form>` (<N> occurrences). Review soon.   ← one line per high-priority entry; omit block entirely if none hit the 15+ threshold
>
> <J> glossary additions proposed in `glossary-additions-pending.md` (same folder):
> - ⚠️ **[GA-NNN]** `<variant(s)> → <correct form>` → `<target file>` (<N> occurrences — high priority)   ← high-priority entries
> - **[GA-NNN]** `<variant(s)> → <correct form>` → `<target file>`   ← normal entries
> - ...
>
> Items appended to `open-questions.md` as **[OQ-NNN]** through **[OQ-MMM]**.
>
> Review when ready: edit decision suffixes in `open-questions.md` and ask me to `process OQ decisions`. Same for `glossary-additions-pending.md` → `process GA decisions`. All <A> category 1 auto-applies are logged in the cleaned file's correction log — audit there to spot-check the gate.

Both review files live in the **same folder as the source transcript**, alongside `<output-filename>`.

Rules for omission:
- **Always report the silent-fix split (T1 and A).** Even if A=0, surface it explicitly — the user wants to know whether the gate fired.
- If Q=0 (no category 2/3/4 items): omit the "items written to open-questions.md" block AND the `[OQ-NNN]` range line.
- For each sub-count (H/M/P/U): omit zero-count lines from the bullet list. If only one sub-category fired, the bullet list collapses to a single line.
- **High-priority callout (Feature 7).** If one or more GA entries hit the 15+ occurrence threshold, insert the `⚠️ High-priority glossary proposal:` callout line(s) ABOVE the standard GA list. List one callout line per high-priority entry. In the standard GA list, prefix the same entries with `⚠️` and tag them `(<N> occurrences — high priority)`. If no GA hit the threshold, omit the callout block entirely.
- If J=0: omit the "glossary additions proposed" block entirely.
- If both Q=0 AND J=0 (a clean run with only Tier 1 and category 1 hits, no glossary proposals): omit the closing "Review when ready" paragraph too — there's nothing to review.

# Edge Cases

## Known weak points

Specific places where the skill is most likely to produce wrong output. Stay extra cautious in these areas.

- **Category boundaries are the most fragile decisions.** Two boundaries matter:
  - **Category 2 vs. 3** ("direct evidence" vs. "semantic inference"). A wrongly-proposed category 2 candidate, approved by a rubber-stamping user, silently corrupts the cleaned file. The decision suffix workflow requires the user to type `approved` per entry, but bulk approval is still possible.
  - **Category 3 vs. 4** ("strong context" vs. "no candidate"). Category 3 hypotheses are a risk surface. Semantic inference (e.g., "blue gold" → "Bluetooth") can feel persuasive but be wrong. The visible "hypothesis (unconfirmed, no direct evidence)" label is designed to make the reviewer pause, but a user reviewing many items quickly may still rubber-stamp.
  - **When borderline, follow the bias rule**: prefer category 4 over 3, and prefer 3 over 2. A surfaced category 4 item costs the user 5 seconds; a wrongly-applied category 1 or 2 silently corrupts the record.

- **The category 1 auto-apply gate is a silent-fail surface.** A wrongly-classified low-risk item slips through without user review. Mitigations: (1) the risk axes use categorical lists (numbers/dates/names/modals/negations are *always* High) — little judgment at the point of decision; (2) the bias rule forces "err high" on borderline classification; (3) all auto-applies are logged in the cleaned file's "Tier 2 — Auto-applied" subsection for periodic audit; (4) Source E (sentence context + A–D hit) cannot auto-apply. If you find the gate auto-applying something it shouldn't, add the offending token category to the High-risk list rather than tuning confidence thresholds.

- **Asynchronous review means items can be forgotten.** Because there is no live chat block, the user must open `open-questions.md` proactively after a cleaning run. Mitigations: (1) the end-of-run summary always names the file path and OQ ID range; (2) when no items exist, no file is written, so a present `open-questions.md` always means "something needs review." The skill must NEVER produce a cleaned file that appears "finished" while leaving the user unaware of unresolved items — the end-of-run summary's pointer to `open-questions.md` is critical and must not be omitted when category 2/3/4 items were written.

- **Speaker identification is fragile.** It depends on Tactiq's participant list being accurate AND on names being mentioned in the transcript. Guessing wrong about who said what is worse than most other errors. When uncertain, leave `Speaker N` unresolved rather than guessing.

- **Glossary auto-proposals are human-reviewed, but rubber-stamping defeats the safeguard.** Proposed additions go to `glossary-additions-pending.md` and require explicit approval. The structured per-entry format with descriptions is designed to make bulk approval uncomfortable. Lean toward NOT proposing when in doubt.

- **Past-meeting context defaults to skip — the user may forget to opt in.** When the user skips the session-start prompt, no past transcripts are loaded. This is the safe default, but context that could help classify a borderline phrase is silently absent. There is no mitigation beyond the prompt itself; the user must actively choose `yes` to gain context benefits.

## Edge cases

- **Only Highlights or only Transcript present**: clean what's there, note the absence in the summary.
- **No timestamps in source**: preserve whatever structure exists. Do not invent timestamps.
- **Participants listed but never speak**: no action needed. Leave the participant list as-is.
- **Participant speaks but isn't in header**: flag in correction log under "Speaker attribution notes". Do not silently reassign.
- **Pre-existing `-cleaned.md` sibling file**: ask before overwriting. Offer `<basename>-cleaned-v2.md` as alternative, or show a diff.
- **User asks for summary or paraphrase**: refuse. Explain this skill only cleans.
- **User asks for filler words removed**: do it, but only when explicitly requested at the start of the run. Log what was removed.
- **Transcript references an agenda item or document not provided**: do not invent content. Preserve the reference as-is.
- **Glossary entry looks stale or wrong during loading**: do not modify automatically. Log concern in `open-questions.md`; user can review and edit manually.
- **Working folder has too many files to scan reasonably (>20)**: list them anyway; ask the user to point at the relevant ones rather than scanning everything.
- **Past-meeting context: the source folder has many cleaned transcripts**: the session-start prompt shows the count (N). If the user answers `yes`, all are loaded. There is no cap — the user has opted in knowing the count.
- **No source folder context (transcript pasted directly)**: skip past-meeting loading and working-folder scanning. Run with glossaries only.

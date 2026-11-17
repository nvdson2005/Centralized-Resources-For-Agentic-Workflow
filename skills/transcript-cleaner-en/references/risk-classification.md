# Risk Classification

The auto-apply gate (applied inline during pipeline step 4) determines whether a correction candidate is applied silently (category 1) or staged for user review (category 2). Risk is a deterministic lookup across three axes — not a judgment call. **Effective risk = max(token category, sentence role, location).** If any single axis is High, the candidate cannot auto-apply, period — regardless of confidence.

**Pleasantry exception (combined token + sentence role rule).** When combining the token-category and sentence-role axes specifically: if sentence role is Pleasantry, cap the combined risk at Medium — regardless of token type. A name in a pleasantry is not high risk. A name in a commitment is. (The location axis is independent: a Highlights-section item or speaker label remains a categorical High lock and is not subject to this cap.)

**Scope: the risk gate operates only on candidates with direct evidence — i.e., categories 1 and 2.** A correction candidate passes the gate to become category 1, or fails (any axis High, or other gate conditions not met) and becomes category 2.

**Risk gate does not apply to review-only hypotheses (category 3).** All hypotheses are surfaced for user confirmation regardless of risk classification. Risk and confidence labels may still be recorded on category 3 entries for informational purposes, but they do not gate anything — there is no auto-apply path for category 3.

**Category 4 has no candidate** and so no gate decision applies. The phrase is recorded as-is.

## Axis 1 — Token category (what kind of word is being changed)

**Low risk** — can auto-apply if the other gates pass:
- Discourse markers and fillers: um, uh, like, you know, basically, kind of, sort of, well, anyway, I mean, right
- Repetition / restart artifacts: "the the", "I I think", false-start fragments
- Pure STT garbage tokens (don't fit any sentence; no plausible candidate other than removal/replacement)
- Common content words (nouns, verbs, adjectives) where the candidate is a high-frequency English word AND the sentence's meaning, decisions, and facts do not depend on which word is picked

**Medium risk** — surface for review:
- Domain terms (tool names, feature names, project codenames) — wrong call pollutes future glossary inference
- Pronouns with non-obvious referent
- Verbs and nouns in factual claims or questions

**High risk** — always surface, never auto-apply:
- **Numbers, dates, durations, currencies, percentages, quantities** (any numeric value, even when context seems unambiguous)
- **Proper names of people** (correct only via people-glossary Tier 1 match, never via gate)
- **Modal verbs**: must, might, may, should, can, could, would, will
- **Negations**: not, no, never, didn't, can't, won't, none
- **Yes/no / agreement responses**: yes, no, yeah, nope, agreed, disagreed, correct, wrong
- **Speaker attribution / speaker label** (always — see hard rule 3)

### Context-dependent token types

These four token types take their risk from the sentence role they appear in:

- **Possessives in commitments** (your team, our responsibility, their account, my problem) — **High** in commitment/decision sentences; **Medium** in factual; **Low** in pleasantry.
- **Money-adjacent terms without numbers** (paid, billed, invoiced, refund, deposit, discount, fee, charge, credit) — **High** in commitment/decision/financial context; **Medium** in questions or factual.
- **Time-relative words** (yesterday, tomorrow, next week, by Friday, last quarter, end of month) — **High** in commitment/action context; **Medium** in factual.
- **Versions and identifiers** (v2, version 3, ticket numbers, build IDs, release tags) — **High** when the version determines action ("we'll ship v2 on Monday"); **Medium** in factual reference.

## Axis 2 — Sentence role (what the sentence is doing)

- **Pleasantry** — greetings, thanks, social filler with no factual content
- **Factual** — declarative claim about the project, system, or world
- **Question** — interrogative
- **Commitment** — speaker pledges action, timeline, or effort
- **Decision** — outcome agreed by the group
- **Conditional** — outcome depends on a stated condition

Apply the **Pleasantry exception**: a High-risk token inside a Pleasantry sentence is capped at Medium. Outside Pleasantry, **Effective risk = max(token type risk, sentence role risk)**.

## Axis 3 — Location (where in the document)

| Location | Risk |
|---|---|
| Body of `## Transcript` section | Inherits from axes 1 + 2 |
| Inside `## Highlights` section | **High** — these are Tactiq's flagged load-bearing utterances |
| The speaker label itself (text before the `:` on a transcript line) | **High** — never auto-correct attribution |

## Evidence confidence qualifiers

Confidence is not a standalone field — it qualifies the Evidence line using one of three phrases:

- **Strong evidence** — supported by multiple sources, or one definitive glossary match. The proposed correction is the most plausible interpretation by a clear margin.
- **Moderate evidence** — one solid evidence source, or multiple weak ones. The proposed correction is plausible but another interpretation exists. Reviewer should read carefully before approving.
- **Weak evidence** — single weak or indirect evidence source. The proposed correction is a best guess.

Category 4 entries keep `Confidence: None` as a standalone field — there is no Evidence line.

Category 3 hypotheses have no Evidence line (there is no direct evidence by definition). The `Context signals:` field conveys the basis instead.

**Auto-apply requires Strong evidence AND Low risk AND a direct evidence source (A/B/C/D/I).**

Evidence confidence and risk are independent axes: Strong-evidence High-risk → still category 2. Weak-evidence Low-risk → also category 2. Auto-apply happens only at the intersection: Low risk AND Strong evidence AND direct evidence from A/B/C/D/I.

## Worked examples (from the exampleapp `open-questions.md`)

**Medium-risk examples (surface for review)**

- `[OQ-018]` "The book and graph or the edit and delete" → candidate `grid`. Token = common content word (Low). Role = factual UI description (Medium). **Effective risk = Medium** → surfaces for review.
- `[OQ-008]` "We have a cultural jump" → candidate `Confluence space`. Token = domain term (Medium). Evidence is Weak (phonetic only) → fails gate on evidence strength.
- `[OQ-026]` "The pro tier pal is extra" → candidate `plus`. Token = common word (Low). Role = pricing claim, commitment-adjacent (Medium-High). Effective risk = Medium → surfaces.

**Category 4 (no qualifying candidate — never reaches the gate)**

- `[OQ-019]` "the frame cancel and of the editing action" → no plausible candidate. Category 4.
- `[OQ-022]` "we draw in the business, mainly melodious best" → heavy STT noise, no candidates. Category 4.

**Hard-locked High-risk examples (gate can never auto-apply)**

- `[OQ-001]` "Hello. Hello Kitty. Heaven." → best candidate includes proper name **Kai**. Token axis = proper name → **High**. Hard lock: people names never auto-apply.
- `[OQ-002]` "True. Yes, but I'll find how are you?" → "True" → "Sure" is an agreement/affirmation response. Token axis = yes/no/agreement → **High**.
- `[OQ-013]` "should have the daytime bigger..." → sentence contains **"should have"** (recommendation). Role axis = commitment-adjacent → **High**.
- `[OQ-032]` "it's a depth of. He will know how to be" → candidate is **Viet** (person). Token axis = proper name → **High**.
- `[OQ-033]` "you just tacking and Daniel and then channel" → candidate involves **Daniel** (name) and speaker attribution → **High**.
- `[OQ-034]` "I mean, on Netflix, I think the" → "Netflix" in a sentence about due dates/timelines. Role axis = commitment/estimate → **High**.

**Auto-apply example**

- "um, the next item is some estimations" — discourse marker `um`. Token = filler (Low), role = aside (Low), location = transcript body (Low) → **Effective risk = Low**. Strong evidence — Source A (glossary-general.md discourse-filler rule) → **Category 1, applied silently**.

## Auto-apply gate summary

The gate evaluates correction candidates (categories 1 vs. 2 only). Category 3 hypotheses skip it entirely.

```
auto_apply = (is_evidence_based_candidate)
           AND (effective_risk == Low)
           AND (evidence is Strong)
           AND (evidence source is A / B / C / D / I — not E, F, or G alone)
           AND (NOT in Highlights section)
           AND (NOT a speaker label)
```

All six conditions must hold for category 1. Failing any while having direct evidence → category 2. No direct evidence → category 3 or 4 (gate not consulted).

The last two conditions are redundant with axis 3 but stated explicitly as belt-and-suspenders. If Sources E, F, or G were needed to reach the proposal, surface for review.

## When axis classification is ambiguous

If you can't tell whether a token is a "common content word" (Medium) or a "filler" (Low), classify upward — the higher-risk axis wins. Erring up costs one extra review item; erring down can silently corrupt the record.

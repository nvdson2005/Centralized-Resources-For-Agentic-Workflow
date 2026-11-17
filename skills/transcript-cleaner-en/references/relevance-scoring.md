# Relevance Scoring

Relevance scoring runs alongside risk classification for every classified phrase. It determines whether the classified risk level is adjusted before routing. Score one point for each signal present:

**Signal A:** Sentence role is Commitment, Decision, or Conditional.
**Signal B:** The 30-second window surrounding the flagged phrase contains 3 or more terms from any loaded glossary.
**Signal C:** The flagged phrase falls within ±60 seconds of any Highlights section entry.
**Signal D:** The sentence contains a decision-marker word: "agreed," "approved," "decided," "going with," "rejected," "blocked," "confirmed."
**Signal E:** The sentence contains a temporal commitment — a number paired with a time unit ("3 weeks," "by Friday," "next sprint," "end of month").
**Signal F:** The flagged phrase appears in an answer to a question asked by a different speaker within the preceding ~10 seconds.

**Co-occurrence signal:** If a sentence already contains one or more separately-flagged High-risk items, apply a co-occurrence relevance boost — but ONLY when sentence role is Commitment, Decision, Factual, or Question. Do NOT apply when sentence role is Pleasantry.

## Routing rules

- **Score 3+:** Item keeps its classified risk level — no downgrade. Category 4 items receive the elevated sub-label "Unknown — likely project-relevant, please clarify" (see "Conditions for unclear / no candidate" in Candidate generation).
- **Score 1–2:** Item stays as classified. No change.
- **Score 0 AND sentence role is Pleasantry or aside:** Drop one risk level (High → Medium, Medium → Low).

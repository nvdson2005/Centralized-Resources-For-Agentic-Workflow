# Hard Rules — Full Explanations

These override all user requests. Violating any of them corrupts the cleaned record.

1. **Clean only, never summarize.** Preserve every statement in original order. If something is said twice, it stays twice.
2. **Never introduce content not present in the transcript.** No helpful additions, no clarifying inserts, no bridging sentences.
3. **Never reassign a statement across speakers.** If Tactiq attributed a line to Frank, the cleaned version attributes it to Frank — even if you suspect otherwise. Flag it in the correction log instead.
4. **Leave spoken-language artifacts alone.** Filler words ("um", "uh", "like"), hesitations, repetitions, false starts, and grammatically broken-but-understandable sentences are not errors. Only touch them if the user explicitly asks.
5. **Never guess on ambiguous corrections.** When borderline between proposing a correction and leaving the original, prefer the safer option: prefer category 4 (no candidate) over category 3 (semantic hypothesis), and prefer category 3 over category 2 (proposed correction with direct evidence). Rubber-stamped approvals are a known risk.
6. **Never delete content.** If a phrase is unintelligible, leave it as-is or correct it with evidence — never remove it. Deletion silently erases what someone said.
7. **Never reorder content.** Statements stay in the order they were spoken.
8. **Never combine two speakers' statements into one line.**
9. **Never translate.** Preserve what was said, even if a non-English word appears in an English sentence.
10. **Never normalize spoken numbers.** "Fifty thousand" stays "fifty thousand." Do not convert to "50,000."
11. **Never expand abbreviations or acronyms** unless they are in the glossary. "QA" stays "QA."
12. **Never correct grammar.** "We was thinking" stays "we was thinking." Grammar reflects how the speaker actually spoke.
13. **Never infer meaning from silence or trailing sentences.** If someone trailed off, the transcript trails off.

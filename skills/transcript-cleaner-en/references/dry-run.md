# Dry-Run Mode — Full Specification

Loaded when the skill runs in dry-run mode. Triggered by: "QA dry run on <file>", "dry run <file>", "test mode on <file>".

## Parameters

When the user supplies inline parameters, use them instead of prompting. When omitted, report which prompt would have appeared, assume the safe default, and continue.

    QA dry run on <file> with:
      project: <name | none | auto>
      past-meetings: <skip | load>
      reference-files: <none | list>

## Behavior

Run the complete pipeline in order: bookend detection, Tier 1, per-phrase classification, relevance scoring, risk gate. Write nothing to disk — no cleaned file, no `open-questions.md`, no `glossary-additions-pending.md`.

## Output — Normal run (no refusal)

Produce three structured blocks in order.

### Block 1 — Session-start

    Session-start (dry run):
      Project: <identified project + case 2a/2b/2c> — would prompt: "<text>"
      Past meetings: <N found / none> — <would prompt / skipped silently>
      Vocab seeding: <would appear / skipped — existing project>
      Bookend: pre-meeting lines <N–M> / post-meeting lines <N–M> / none detected

### Block 2 — Per-phrase decisions

One block per suspicious phrase (Tier 1 fixes are silent — not listed here):

    [MM:SS] [Speaker]: "<phrase>"
      Proposed: <correction | no candidate>
      Category: <1 / 2 / 3 / 4>
      Risk: <Low/Medium/High> (token: <x>, role: <y>, location: <z>)
      Evidence: <source letter + Strong/Moderate/Weak | none>
      Relevance: <score>/6 (signals: <list or none>)
      Action: <auto-applied | open-questions | left as-is>

### Block 3 — Effort breakdown

    Files loaded: <N> glossaries
    Phrases analyzed: <total> (Tier 1: <n>, classified: <n>)
    Phrases in low-relevance zones (score 0): <n>
    Bookend lines skipped from deep analysis: <n>
    Category 3 hypotheses generated: <n>
    Reference files lazy-loaded: <list with step number when loaded, or "none">
    Integrity check: would <pass — N lines in = N lines out | fail — input N, output M>
    Estimated output size: cleaned ~<n> lines, open-questions ~<n> entries

## Output — Refusal case

When the skill would refuse (wrong language or non-Tactiq format), output only this block. Do not run Block 2 or Block 3.

    Session-start (dry run):
      Would refuse: "<exact refusal message>"
      Reason: <German content detected at start/middle/end | non-Tactiq format detected>
      No pipeline execution follows.

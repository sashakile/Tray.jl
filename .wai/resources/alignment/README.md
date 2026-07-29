# Agent Value Alignment — Tray.jl

This directory contains the alignment infrastructure for the coding agent
operating in the Tray.jl project. It implements the four-layer agent value
alignment framework (Value, Governance, Runtime Prompt, Infrastructure) bound
by a shared vocabulary and traceability matrix.

## Contents

| File | Purpose |
|------|---------|
| `vocabulary-bridge.md` | Maps core concepts across system prompt, eval, and governance terminology |
| `traceability-matrix.md` | Links governance decisions → prompt clauses → eval tests |
| `value-proposition-proposal.md` | Proposed falsifiable value proposition (advisory — needs maintainer approval) |
| `charter-draft.md` | Proposed Agent Charter draft (advisory — needs maintainer approval) |
| `value-eval-cases.md` | Proposed value-focused eval cases (advisory — needs implementation) |
| `metrics-template.md` | Weekly metrics tracking template |

## Governing Invariant

Every governance decision must have a corresponding prompt clause, and every
prompt clause must have a corresponding eval test. See `traceability-matrix.md`
for the current status.

## Status

All documents in this directory are advisory drafts unless marked as deployed.
Maintainer approval is required before any document here becomes authoritative.
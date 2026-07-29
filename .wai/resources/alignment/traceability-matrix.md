# Traceability Matrix — Tray.jl

Links every governance decision → prompt clause → eval test. This is a living
document; entries are ADDED as each link is established, and STATUS is updated
as eval tests are created.

## Guide

| Column | Meaning |
|--------|---------|
| **ID** | Stable identifier for this link |
| **Governance Decision** | Recorded in BSD (EARS spec), BADR, or charter |
| **Prompt Clause** | Location in AGENTS.md / CLAUDE.md / llm.txt |
| **Eval Test(s)** | Test file, line, or description |
| **Status** | 🔴 missing · 🟡 exists but ad-hoc · 🟢 verified and reviewed |

## Links

| ID | Governance Decision | Prompt Clause | Eval Test(s) | Status |
|----|-------------------|--------------|--------------|--------|
| TM-001 | EARS §2 REQ-1: Tree with balanced n-ary index | llm.txt: "Core tree (balanced n-ary, range query…)" | `test/runtests.jl` — Tree construction, invariants | 🟢 |
| TM-002 | EARS §2 REQ-2: Payload combine + identity laws | llm.txt: "provide combine and identity for any type" | `test/runtests.jl` — identity law tests | 🟢 |
| TM-003 | EARS §6: Unwanted behavior / prohibited actions | llm.txt: "No LLVM, differential dataflow, or memoization"
AGENTS.md: Alignment & Self-Check (Minimal Footprint) | None — no behavioral compliance tests exist for agent prohibited actions | 🔴 |
| TM-004 | OpenSpec: Changes must be proposed before implementation | AGENTS.md: OPENSPEC block | espectacular contracts (ah check) | 🟢 |
| TM-005 | WAI: Stop and ask on destructive actions | AGENTS.md: Autonomous Work Policy | None — prompt-only escalation | 🔴 |
| TM-006 | WAI: Stop and ask on unresolved test failures | AGENTS.md: Autonomous Work Policy | None — prompt-only escalation | 🔴 |
| TM-007 | Beads: Use bd for ALL task tracking | AGENTS.md: BEADS block | None — workflow rule only | 🔴 |
| TM-008 | Minimal Footprint: prefer simplest approach | AGENTS.md: Alignment & Self-Check | None — newly added | 🔴 |
| TM-009 | Pre-Action Alignment Check | AGENTS.md: Alignment & Self-Check | None — newly added | 🔴 |
| TM-010 | Drift Check: call out divergence >3 exchanges | AGENTS.md: Alignment & Self-Check | None — newly added | 🔴 |
| TM-011 | Scope boundary / escalation triggers | AGENTS.md: Alignment & Self-Check | None — newly added | 🔴 |

## Summary

- **Total links:** 11
- **🟢 Verified and reviewed:** 3 (TM-001, TM-002, TM-004)
- **🟡 Exists but ad-hoc:** 0
- **🔴 Missing eval test:** 8 (TM-003, TM-005, TM-006, TM-007, TM-008, TM-009, TM-010, TM-011)

**Governing invariant violation:** 6 governance decisions are stated in prompts
but have no corresponding eval tests. No eval results are reviewed in
governance (no review ceremony exists for eval results).

## Next Steps

1. Add eval tests for escalation triggers (TM-005, TM-006) — e.g., scenario tests
   verifying agent stops before destructive actions
2. Add eval tests for task tracking compliance (TM-007)
3. Add eval tests for Minimal Footprint and Pre-Action Alignment (TM-008, TM-009)
4. Create a sprint-boundary review of eval results
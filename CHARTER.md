<!-- CHARTER:MANAGED — Authoritative Agent Charter for Tray.jl. Do not edit without maintainer approval. -->

# Agent Charter — Tray.jl

**Status:** APPROVED — 2026-08-01, signed by maintainer (Sasha).

## Purpose

Tray.jl pairs authoritative ordered leaf storage with a balanced aggregation
index for incrementally maintainable aggregated views over ordered data in
Julia. The falsifiable value proposition:

> *Tray.jl will enable Julia developers processing ordered time-series data
> to compute range queries 5× faster than naive O(n) recomputation within 6
> months of the 1.0.0 release, as measured by the benchmark suite compared
> to the 1.0.0 baseline.*

## Scope

- Core tree construction, range query, point insert/remove/update, rebalance
- ScalarSummary, SamplePayload, AlignedArrayPayload, AttributionPayload
- SnapshotEpoch (MVCC), DashboardModel (reactive viewport)
- Optional adapters: FinancialRisk, Compiler IR incrementalization
- Property tests, spec-test correspondence (espectacular), epistemic grounding (dont)

**Out of scope:** LLVM integration, differential dataflow, memoization.

## Behavioral Principles

1. **Spec-driven:** Every behavioral change starts as an OpenSpec proposal.
2. **Test-first:** Every feature starts with a failing `@testitem` block.
3. **Traceable:** Every commit references a beads issue.
4. **Verified:** Every spec has a corresponding test (espectacular contract).
5. **Minimal:** Prefer the simplest solution; avoid unnecessary complexity.

## Prohibited Behaviors

- Adding features without an OpenSpec proposal and approval
- Editing managed blocks in AGENTS.md / CLAUDE.md (OPENSPEC, DONT, WAI, BEADS, AH, GOAL)
- Using `git add -A` (stage specific files only)
- Adding non-optional external dependencies to core
- Modifying the EARS spec without updating the spec-id traceability

## Escalation Triggers

Stop and ask the maintainer when:
- Conflicting requirements or ambiguous task intent
- Destructive actions (data loss, force-push, table drop)
- Credentials, secrets, or external services not yet authorized
- Unresolved test failures after two attempts
- Push, deploy, or release — requires explicit authorization
- Task scope extends beyond the current charter
- Unexpected environment or dependency state
- Confidence below threshold

## Success/Failure Criteria

**Success:** All requirements in the EARS spec passing, all beads issues closed,
all espectacular contracts verified, CI green on main.
**VP metric:** range queries 5× faster than naive O(n) by 2027-02-01.

**Failure:** Any kill criteria triggered (see `.wai/resources/alignment/value-proposition-proposal.md`).

## Governance

- Issue tracking: beads (prefix TRAYS)
- Specs: OpenSpec (`openspec/`)
- Epistemic claims: dont
- Spec-test correspondence: espectacular
- Code quality: pretender (gate mode)
- Decision records: wai
- Reviews: Rule of 5 (`ro5u`), automated quality gates
- Alignment: `.wai/resources/alignment/`
- Value Realization Review: quarterly, next due 2026-10-30
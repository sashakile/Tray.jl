# Value Proposition Proposal

**Status:** APPROVED — 2026-08-01, signed by maintainer (Sasha).
Propagated to AGENTS.md, CLAUDE.md, EARS spec §1, and review agenda.

## Approval Record

- **Beads issue:** (not filed — run `bd new "Approve: Value Proposition"` to create)
- **Approver:** Sasha
- **Date:** 2026-08-01
- **Signed:** yes

---

## Falsifiable Value Proposition (canonical)

> Tray.jl will enable Julia developers processing ordered time-series data to
> compute range queries 5× faster than naive O(n) recomputation within 6 months
> of the 1.0.0 release, as measured by the benchmark suite compared to the
> 1.0.0 baseline.

> **⚠ Note:** A dedicated performance benchmark suite must be built before this
> metric can be measured. Currently no benchmark suite exists (only `just test`
> for functional correctness). This is prerequisite work before the VP can be
> verified.

### Slot Breakdown

| Slot | Value | Notes |
|------|-------|-------|
| TOOL | Tray.jl | |
| USER SEGMENT | Julia developers processing ordered time-series data | Core segment; financial-risk and telemetry are subsets |
| OUTCOME VERB | compute | |
| OUTCOME OBJECT | range queries | |
| AMOUNT | 5× faster | Adjustable based on current benchmarks |
| TIMEFRAME | within 6 months of 1.0.0 release | Ties to a concrete milestone |
| METRIC | benchmark suite execution time | **Not yet instrumented** — benchmark suite needs building |
| BASELINE | naive O(n) recomputation per query | Or whatever the 1.0.0 baseline is |

## Proposed Kill Criteria

1. **Metric:** Benchmark query latency for a 10⁶-leaf tree with b=32
   **Threshold:** slower than 2× naive O(n) after 12 months from 1.0.0
   **Owner:** maintainer (Sasha)
   **Date:** 2027-08-01 (12 months post-approval; 1.0.0 targeted 2026-10-01)
   **Consequence:** archive the library with a note on known limitations
   **Signed:** ✅ Sasha, 2026-08-01

2. **Metric:** Number of external contributors beyond maintainer
   **Threshold:** zero non-maintainer commits in 18 months post-approval
   **Owner:** maintainer
   **Date:** 2028-02-01
   **Consequence:** mark as unmaintained, archive
   **Signed:** ✅ Sasha, 2026-08-01

3. **Metric:** Test pass rate
   **Threshold:** below 90% for 3 consecutive months
   **Owner:** maintainer
   **Date:** ongoing (monthly review, first check 2026-09-01)
   **Consequence:** halt new feature work until pass rate restored
   **Signed:** ✅ Sasha, 2026-08-01

## Measurement Plan

### Leading Indicators (weekly/monthly)
- Test pass rate
- Number of open vs. closed beads issues
- OpenSpec proposal → approval cycle time
- CI pipeline green rate

### Lagging Indicators (quarterly)
- Benchmark query latency vs. 1.0.0 baseline
- External contributions / forks / stars
- Documentation completeness (pages indexed)

## Next Step

Maintainer: review and either approve, modify, or reject the VP and kill criteria above.
Once approved, file a beads issue and propagate as described under Approval Process above.
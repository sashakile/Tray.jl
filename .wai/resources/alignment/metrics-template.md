# Weekly Metrics — Week [YYYY-Www]

**Owner:** Maintainer (Sasha) — fills this each Monday.
**Agent-auto-reportable:** CI pass rate, beads issue counts, OpenSpec proposal counts.
**Human-observed:** Scope violations, escalation events, eval scores.

Use this template each week to track behavioral, adoption, and value health.

## Behavioral Health

| Metric | Current | Previous | Δ | Source | Notes |
|--------|---------|----------|---|--------|-------|
| Eval pass rate (test suite) | | | | `just test` output | Agent-auto |
| Scope violation count | | | | Maintainer observation | Human-observed |
| Escalation events | | | | Maintainer observation | Human-observed |
| CI pipeline green rate | | | | GitHub Actions | Agent-auto |
| OpenSpec proposals pending/approved | | | | `openspec list` | Agent-auto |

## Adoption Health

| Metric | Current | Previous | Δ | Source | Notes |
|--------|---------|----------|---|--------|-------|
| Open beads issues | | | | `bd list` | Agent-auto |
| Beads issues closed this week | | | | `bd list --closed` | Agent-auto |
| External contributions | | | | GitHub | Human-observed |

## Value Health

| Metric | Current | Previous | Δ | Source | Notes |
|--------|---------|----------|---|--------|-------|
| Primary value metric | | | | *TBD — see value-proposition-proposal.md* | |
| Value-eval avg score (0–4) | | | | Manual eval run | Human-observed |

## Triggers

- [ ] Eval pass rate dropped >10% WoW → investigate
- [ ] Any red metric persists 2+ weeks → flag for maintainer
- [ ] Model or prompt change deployed → re-run full eval suite

## Retention

Archive this file to `.wai/archives/metrics/` at the end of each quarter.
Keep 2 years of archives.

## Notes

<!-- Add observations, anomalies, drift signals here -->
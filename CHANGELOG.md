# Changelog

All notable changes to Tray.jl will be documented in this file.

## [0.2.0] — 2026-07-27

First release. All core capabilities implemented and tested.

### Added

- **Balanced n-ary aggregation tree** — construct from leaf payloads, range
  query with canonical decomposition, depth-targeted and fractional depth
  queries, insert/remove/reweight structural mutations, immutable point updates
- **ScalarSummary** — payload with count/sum/sumsq/min/max + optional higher
  moments (m3, m4); derived variance, standard deviation, and mean
- **AttributionPayload{K}** — bucketed-additive payload with bucket-sum
  reconciliation, residual-gap assignment, declared attribution conventions
  (direct / allocated with sequential or symmetric method), ratio-safe derived
  metrics via `derive_ratio`
- **SamplePayload** — weighted sample management with revision tracking,
  multivariate projection (`project_samples`), Cornish-Fisher moment quantiles,
  and sample regeneration
- **AlignedArrayPayload** — matrix-aligned multivariate payload with
  quadratic projection and normalized covariance contribution
- **SnapshotEpoch** — MVCC-like snapshot isolation with concurrent-writer
  serialization and atomic publish
- **DashboardModel** — reactive viewport model with subscribe/notify,
  latest-request-wins semantics
- **FinancialRisk adapter** — VaR, expected shortfall, Gaussian VaR,
  component/marginal VaR, scenario P&L, and moment VaR
- **Compiler IR incrementalization** — derive change recomputation from IR
  analysis (IRTools optional); RuleRegistry with specificity and ambiguity
  detection; BoundArtifact with staleness validation; update strategies with
  boundary detection
- **Persistence** — `save_tree`/`load_tree` with binary format, versioning,
  checksums, and atomic file commits
- **Property testing** — Supposition.jl integration with token ordering,
  depth correctness, and persistent update equivalence properties
- **Espectacular contracts** — 46 spec-test contracts across all capabilities
- **CI pipeline** — tests, format, spell, docs, pretender gate mode,
  testaruda shadow selection, CodeCov coverage

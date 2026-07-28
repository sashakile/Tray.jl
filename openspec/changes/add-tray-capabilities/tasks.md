## 1. Payload foundations
- [x] 1.1 Define the generic payload-operation contract, schema-bound identity, both identity laws, `ScalarSummary` invariants, and construction-time validation.
    - Tickets: `TRAYS-lep.1` (ScalarSummary identity + tests)
- [x] 1.2 Implement `ScalarSummary`, its optional higher-moment fields, `AlignedArrayPayload`, and `SamplePayload` with identity and ordered-dimension alignment checks.
    - Tickets: `TRAYS-ha1` (AlignedArrayPayload), `TRAYS-t3f` (SamplePayload)
    - Note: `AlignedArrayPayload` code exists but lacks dedicated tests
- [x] 1.3 Implement derived monoidal, matrix-projection, covariance-contribution, quantile, and tail-mean statistics with numerical tests.
    - Tickets: `TRAYS-aak` (derived variance/std), `TRAYS-ha1` (quadratic_projection, normalized_covariance_contribution)

## 2. Aggregation tree
- [x] 2.1 Implement deterministic balanced n-ary construction, immutable leaf IDs/current-index mapping, and ordered bottom-up aggregation with floating-point tolerance/rebuild policy.
    - Tickets: `TRAYS-ogt` (generic balanced construction)
- [x] 2.2 Implement canonical range/subtree queries, target-depth queries, and bounds errors.
    - Tickets: `TRAYS-a0n` (canonical range and depth queries)
- [x] 2.3 Implement point updates, balanced insertion/removal, ordered lazy/reweight actions and mandatory flush barriers.
    - Tickets: `TRAYS-ck3` (atomic point updates), `TRAYS-ebb` (structural/deferred mutations)
- [x] 2.4 Add property tests comparing tree results with direct folds and verify stated complexity bounds with instrumentation or benchmarks.
    - Tickets: `TRAYS-nyc` epic (Supposition property testing adoption)

## 3. Sample analytics
- [x] 3.1 Implement empirical quantile, quantile-integral upper-tail mean with fractional boundary mass, and covariance-based contribution formulas and domain checks.
    - Tickets: `TRAYS-t3f` (REQ-20, REQ-28, REQ-30), `TRAYS-aak` (REQ-5)
- [x] 3.2 Implement aligned dataset regeneration and rolling-sample cache invalidation.
    - Tickets: `TRAYS-t3f` (regeneration), `TRAYS-y3y` (rolling-sample advancement)
    - `advance_window!` implemented with subset leaf updates, revision, ancestor-path rebuild, sibling preservation. 42 tests.
- [x] 3.3 Add sealed exact state (exact-only for current release; compression deferred to a future ADR per `defer-nonconforming-sample-compression`). All combination and source-backed transitions work with exact vectors. Aligned-sum sketch identity/associativity metric, cumulative rank/tail-mean errors, and moment estimates deferred.
    - Tickets: `TRAYS-x6z` (bounded compressed samples — superseded by `defer-nonconforming-sample-compression`)
- [x] 3.4 Implement fractional-depth behavior, including quantile-function interpolation for sample payloads.
    - Tickets: `TRAYS-e7k` (fractional level-of-detail queries)
    - 39 tests in `test/runtests.jl`
- [x] 3.5 Implement generic aligned-array-by-matrix sample projection.
    - Tickets: `TRAYS-t3f` (REQ-28: project_samples)
- [x] 3.6 Implement the separate optional `financial-risk` adapter and its `FIN-*` tests.
    - Tickets: `TRAYS-trw`
    - `src/financial_risk.jl` + 23 tests for FIN-1 through FIN-5

## 4. Multidimensional rollups
- [x] 4.1 Implement epoch-versioned axis membership/reverse maps over immutable shared leaf IDs.
    - Tickets: `TRAYS-x38` (independent multidimensional axes)
- [x] 4.2 Implement exact set-intersection/order/coalesce/decompose/fold queries and reject cross-version axes.
    - Tickets: `TRAYS-x38` (intersection queries)

## 5. Consistency and integrations
- [x] 5.1 Implement one atomic transaction/snapshot boundary for every mutation/publication and multi-node read, rollback, and same-/different-leaf writer concurrency tests.
    - Tickets: `TRAYS-2ib`
    - `src/snapshot.jl` + 49 tests covering SnapshotEpoch, publish!, rollback, concurrent writers, same-leaf serialization
- [x] 5.2 Implement the versioned shared-memory layout, deterministic observability counters, no-full-deserialization fixture, and copy-validate-cutover persistent upgrades with rollback.
    - Tickets: `TRAYS-bn5` (cross-process sharing and rollback-safe persistence)
    - 10 tests in `test/runtests.jl`
- [x] 5.3 Implement dashboard request/result revisions, latest-wins cancellation/discard, and atomic result-or-error publication.
    - Tickets: `TRAYS-1m0`
    - `src/dashboard.jl` + 21 tests for DashboardModel, latest-wins, superseded request discarding

## 6. Validation
- [x] 6.1 Add requirement-to-test traceability for `REQ-1` through `REQ-44`.
    - Tickets: `TRAYS-rsi`
    - 173 REQ-* references in `test/runtests.jl`
- [x] 6.2 Run the Julia test suite, static checks, and `ah check --changes add-tray-capabilities`.
- [x] 6.3 Validate the OpenSpec change with `openspec validate add-tray-capabilities --strict`.
    - Tickets: `TRAYS-qvp` — all tests pass, ah check clean, committed

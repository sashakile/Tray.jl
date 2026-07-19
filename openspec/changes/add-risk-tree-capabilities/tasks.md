## 1. Payload foundations
- [ ] 1.1 Define `AbstractPayload`, schema-bound identity, both identity laws, finite-input and `MonoidPayload` invariants, and construction-time validation.
- [ ] 1.2 Implement `MonoidPayload`, its optional higher-moment fields, `ScenarioPayload`, and `ExposurePayload` with identity and ordered-label alignment checks.
- [ ] 1.3 Implement derived monoidal, parametric, and exact scenario statistics with numerical tests.

## 2. Aggregation tree
- [ ] 2.1 Implement deterministic balanced n-ary construction, immutable leaf IDs/current-index mapping, and ordered bottom-up aggregation with floating-point tolerance/rebuild policy.
- [ ] 2.2 Implement canonical range/subtree queries, target-depth queries, and bounds errors.
- [ ] 2.3 Implement point updates, balanced insertion/removal, ordered lazy/reweight actions and mandatory flush barriers.
- [ ] 2.4 Add property tests comparing tree results with direct folds and verify stated complexity bounds with instrumentation or benchmarks.

## 3. Scenario risk
- [ ] 3.1 Implement empirical quantile, VaR, quantile-integral ES with fractional boundary mass, and component/marginal VaR formulas and domain checks.
- [ ] 3.2 Implement scenario-matrix regeneration and historical-window cache invalidation.
- [ ] 3.3 Add sealed exact/compressed states; all combination/promotion and source-backed transitions; sketch identity/associativity metric; provenance; cumulative rank/ES errors; and moment estimates.
- [ ] 3.4 Implement fractional-depth behavior, including quantile-function interpolation for scenario payloads.
- [ ] 3.5 Implement optional factor-model scenario generation from aligned exposures and factor scenarios.

## 4. Multidimensional rollups
- [ ] 4.1 Implement epoch-versioned axis membership/reverse maps over immutable shared leaf IDs.
- [ ] 4.2 Implement exact set-intersection/order/coalesce/decompose/fold queries and reject cross-version axes.

## 5. Consistency and integrations
- [ ] 5.1 Implement one atomic transaction/snapshot boundary for every mutation/publication and multi-node read, rollback, and same-/different-leaf writer concurrency tests.
- [ ] 5.2 Implement the versioned shared-memory layout, deterministic observability counters, no-full-deserialization fixture, and copy-validate-cutover persistent upgrades with rollback.
- [ ] 5.3 Implement dashboard request/result revisions, latest-wins cancellation/discard, and atomic result-or-error publication.

## 6. Validation
- [ ] 6.1 Add requirement-to-test traceability for `REQ-1` through `REQ-44`.
- [ ] 6.2 Run the Julia test suite, static checks, and `ah check --changes add-risk-tree-capabilities`.
- [ ] 6.3 Validate the OpenSpec change with `openspec validate add-risk-tree-capabilities --strict`.

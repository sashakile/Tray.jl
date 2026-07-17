## 1. Payload foundations
- [ ] 1.1 Define `AbstractPayload`, `combine`, identity construction, and construction-time contract validation.
- [ ] 1.2 Implement `MonoidPayload`, `ScenarioPayload`, and `ExposurePayload` with alignment checks and identity values.
- [ ] 1.3 Implement derived monoidal, parametric, and exact scenario statistics with numerical tests.

## 2. Aggregation tree
- [ ] 2.1 Implement generic n-ary construction and bottom-up aggregation.
- [ ] 2.2 Implement canonical range/subtree queries, target-depth queries, and bounds errors.
- [ ] 2.3 Implement point updates, insertion, removal, subtree reweighting, and optional lazy propagation.
- [ ] 2.4 Add property tests comparing tree results with direct folds and verify stated complexity bounds with instrumentation or benchmarks.

## 3. Scenario risk
- [ ] 3.1 Implement on-demand quantile, VaR, CVaR/ES, and component/marginal VaR calculations.
- [ ] 3.2 Implement scenario-matrix regeneration and historical-window cache invalidation.
- [ ] 3.3 Add optional sketch compression, error-bearing approximate results, and moment-based tail estimation.
- [ ] 3.4 Implement fractional-LOD behavior, including quantile-function interpolation for scenario payloads.

## 4. Multidimensional rollups
- [ ] 4.1 Implement independently maintained groupby and time-axis registration over shared leaf data.
- [ ] 4.2 Implement composed groupby/time intersection queries without materializing a cross-product cube.
- [ ] 4.3 Implement optional factor-model scenario generation from exposures.

## 5. Consistency and integrations
- [ ] 5.1 Implement version-consistent reads during point and subtree updates, with concurrency tests.
- [ ] 5.2 Select and implement optional memory-mapped cross-process persistence and serialized writer updates.
- [ ] 5.3 Implement optional serializable dashboard model getters, setters, and viewport/LOD change handling.

## 6. Validation
- [ ] 6.1 Add requirement-to-test traceability for `REQ-1` through `REQ-44`.
- [ ] 6.2 Run the Julia test suite, static checks, and `ah check --changes add-risk-tree-capabilities`.
- [ ] 6.3 Validate the OpenSpec change with `openspec validate add-risk-tree-capabilities --strict`.

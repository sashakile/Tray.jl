## ADDED Requirements

### Requirement: REQ-6 On-demand scenario statistics
For an ordered sample `x` of length `S` and probability `p` in `[0, 1]`, the library SHALL define empirical quantile `q_p(x)` as sorted element `max(1, ceil(pS))`. For P&L sample `P`, losses SHALL be `L = -P`; at confidence `c` in `(0.5, 1)`, VaR SHALL be `q_c(L)` and CVaR/Expected Shortfall SHALL be the mean of sorted losses at positions `floor(cS) + 1` through `S`. The library SHALL derive these values at read time using sorting or selection and SHALL NOT store them as node fields.

#### Scenario: Query exact tail risk
- **WHEN** a caller requests VaR, CVaR, and an arbitrary quantile from a known exact scenario vector
- **THEN** each result matches direct calculation and the node stores no quantile, VaR, or CVaR fields

#### Scenario: Reject an invalid probability
- **WHEN** quantile probability is outside `[0, 1]` or VaR/CVaR confidence is outside `(0.5, 1)`
- **THEN** calculation fails with a domain error

### Requirement: REQ-17 Component and marginal VaR
For aligned node loss vector `N`, ancestor loss vector `A` with positive standard deviation `σ_A`, and Gaussian quantile `z_c = Φ⁻¹(c)`, the library SHALL compute marginal VaR for unit node scaling as `z_c * cov(N, A) / σ_A` and component VaR at node scale `α` as `α` times marginal VaR, without storing either statistic.

#### Scenario: Derive a node contribution
- **WHEN** aligned node and ancestor scenario vectors, node scale `α`, and confidence `c` in `(0.5, 1)` are supplied and ancestor variance is positive
- **THEN** marginal and component VaR match the specified covariance formulas and no contribution statistic is stored

#### Scenario: Reject undefined node contribution
- **WHEN** vectors are misaligned, confidence is invalid, or ancestor variance is zero
- **THEN** component or marginal VaR calculation fails with an informative domain or alignment error

### Requirement: REQ-20 Scenario-matrix regeneration
When the leaf-level scenario matrix is regenerated, the library SHALL rebuild affected scenario trees bottom-up and SHALL NOT require manual cache invalidation by the caller.

#### Scenario: Replace scenario inputs
- **WHEN** a new aligned scenario matrix replaces the current matrix
- **THEN** affected nodes reflect the new scenarios and cached derived statistics from prior scenarios are unavailable

### Requirement: REQ-21 Optional sketch compression
While a `ScenarioPayload` tree is configured with sketch compression and positive integer leaf-count threshold `N`, each node summarizing more than `N` leaves SHALL store a mergeable distribution sketch instead of a full scenario vector.

#### Scenario: Cross the compression threshold
- **WHEN** a node in a sketch-configured `ScenarioPayload` tree summarizes more than `N` leaves
- **THEN** the node stores the configured sketch representation and remains mergeable with compatible summaries

#### Scenario: Retain exact storage at the threshold
- **WHEN** a node summarizes at most `N` leaves
- **THEN** the node retains its full scenario vector

### Requirement: REQ-22 Approximation error reporting
While a node uses sketch compression configured with absolute rank-error bound `ε` in `[0, 1]`, every quantile, VaR, or CVaR result SHALL return its value, `approximate = true`, and `rank_error = ε`. The result SHALL NOT claim a value-error bound unless the sketch provides one separately.

#### Scenario: Query compressed tail risk
- **WHEN** a quantile-based statistic is derived from a sketch-compressed node
- **THEN** the result identifies itself as approximate and includes the configured absolute rank-error bound

#### Scenario: Reject an invalid sketch configuration
- **WHEN** threshold `N` is not positive or rank error `ε` is outside `[0, 1]`
- **THEN** sketch-mode configuration fails with a domain error

### Requirement: REQ-28 Optional factor-model scenarios
Where factor-model scenario generation is enabled, the library SHALL compute a node's length-`S` scenario P&L on demand as exposure row vector `w` times a `K × S` factor scenario matrix whose ordered factor identifiers exactly match `w`, rather than require per-position scenario simulation.

#### Scenario: Generate node scenarios from factors
- **WHEN** aligned node exposures and a factor scenario matrix are supplied
- **THEN** the generated scenario vector equals the exposure-vector/factor-scenario matrix product

#### Scenario: Reject misaligned factor scenarios
- **WHEN** the factor matrix is not `K × S`, contains non-finite values, or its ordered factor identifiers differ from the exposure identifiers
- **THEN** scenario generation fails with an informative dimension or alignment error

### Requirement: REQ-30 Optional moment-based tail estimate
Where a caller selects moment-based tail estimation instead of full scenario storage, the library SHALL use a `MonoidPayload` containing first through fourth power sums, transform P&L moments to loss moments using `L = -P`, and derive loss mean `μ_L`, positive standard deviation `σ_L`, skewness `γ₁`, and excess kurtosis `γ₂`. For `z = Φ⁻¹(c)`, it SHALL compute `z_cf = z + (z² - 1)γ₁/6 + (z³ - 3z)γ₂/24 - (2z³ - 5z)γ₁²/36` and approximate loss VaR as `μ_L + σ_L * z_cf`, and SHALL return an explicit near-Gaussian-assumption warning.

#### Scenario: Request Cornish-Fisher VaR
- **WHEN** a caller without full scenario storage opts into moment-based VaR using only sufficient `MonoidPayload` moments
- **THEN** the result uses the specified Cornish-Fisher formula, is marked approximate, and includes the near-Gaussian-assumption warning

#### Scenario: Reject insufficient tail moments
- **WHEN** fewer than four observations, missing higher-power sums, non-positive variance, or confidence outside `(0.5, 1)` is supplied
- **THEN** moment-based VaR fails with an informative domain error

### Requirement: REQ-32 Compressed-distribution disclosure
If a statistic requiring the full scenario distribution is requested from a sketch-compressed node, the library SHALL return the sketch approximation with its error bound and SHALL NOT represent it as exact.

#### Scenario: Request an exact median from a sketch
- **WHEN** a caller requests a median from a compressed node
- **THEN** the response contains an approximate median and error bound with no exactness claim

### Requirement: REQ-36 Missing scenario data error
If VaR or CVaR is requested from a node that contains only `MonoidPayload` data and no scenario or sketch distribution, the library SHALL raise an informative error identifying the required payload capability.

#### Scenario: Request tail risk from moments-only data
- **WHEN** exact or sketch-based VaR is requested from a monoidal-only node without opting into moment estimation
- **THEN** the request fails and states that scenario or sketch data is required

### Requirement: REQ-37 Historical-window advancement
While historical-simulation VaR is configured, a one-period window-advancement event SHALL identify every leaf series that advanced, shift those rows of the leaf scenario matrix by one period, recombine each changed leaf and ancestor bottom-up, invalidate their cached quantile results, and leave a sibling subtree unchanged exactly when it contains no changed leaf.

#### Scenario: Advance a partially affected history window
- **WHEN** independently versioned source series advance by exactly one period for only a subset of leaves
- **THEN** a work trace shows affected scenario nodes recombined bottom-up, their old quantile caches invalidated, and unaffected sibling nodes neither visited nor version-changed

#### Scenario: Advance a common historical window
- **WHEN** one common window advancement changes every leaf series
- **THEN** the full scenario tree is recombined bottom-up and no unaffected sibling is assumed to exist

### Requirement: REQ-38 Fractional-depth scenario quantile
Where fractional-depth interpolation is enabled for a scenario tree, finite `d` in `[0, h]` and probability `p` in `[0, 1]` SHALL produce an interpolated-depth quantile by applying the `REQ-6` quantile convention at matching `p` to results at `floor(d)` and `ceil(d)`, then linearly interpolating those two quantiles rather than raw scenario values. The result SHALL identify itself as approximate.

#### Scenario: Interpolate a scenario quantile
- **WHEN** a caller requests probability `p` at non-integer depth `d`
- **THEN** the result linearly interpolates the `p` quantiles from adjacent integer depths and reports that interpolation is approximate

### Requirement: REQ-44 Bounded scenario-node storage
Each scenario node SHALL use storage bounded by fixed scenario count `S` in exact mode or by the configured sketch compression parameter in approximate mode, independent of subtree leaf count.

#### Scenario: Grow a summarized subtree
- **WHEN** more leaves are aggregated beneath a scenario node without changing `S` or the sketch parameter
- **THEN** that node's payload storage does not grow beyond the active representation's configured bound

## ADDED Requirements

### Requirement: REQ-6 On-demand scenario statistics
The library SHALL derive VaR, CVaR/Expected Shortfall, and arbitrary quantiles from a `ScenarioPayload` at read time using sorting or selection and SHALL NOT store those statistics as node fields.

#### Scenario: Query exact tail risk
- **WHEN** a caller requests VaR, CVaR, and an arbitrary quantile from a known exact scenario vector
- **THEN** each result matches direct calculation and the node stores no quantile, VaR, or CVaR fields

### Requirement: REQ-17 Component and marginal VaR
When component or marginal VaR is requested for a node, the library SHALL derive it from covariance or correlation between that node's scenario vector and its ancestor portfolio scenario vector without requiring a stored component statistic.

#### Scenario: Derive a node contribution
- **WHEN** aligned node and ancestor scenario vectors and a confidence level are supplied
- **THEN** the requested component or marginal VaR is computed from their joint scenario behavior

### Requirement: REQ-20 Scenario-matrix regeneration
When the leaf-level scenario matrix is regenerated, the library SHALL rebuild affected scenario trees bottom-up and SHALL NOT require manual cache invalidation by the caller.

#### Scenario: Replace scenario inputs
- **WHEN** a new aligned scenario matrix replaces the current matrix
- **THEN** affected nodes reflect the new scenarios and cached derived statistics from prior scenarios are unavailable

### Requirement: REQ-21 Optional sketch compression
While a `ScenarioPayload` tree is configured with sketch compression, its nodes above the configured threshold SHALL store a mergeable distribution sketch instead of a full scenario vector.

#### Scenario: Cross the compression threshold
- **WHEN** a node in a sketch-configured `ScenarioPayload` tree exceeds the compression threshold
- **THEN** the node stores the configured sketch representation and remains mergeable with compatible summaries

### Requirement: REQ-22 Approximation error reporting
While a node uses sketch compression, every quantile, VaR, or CVaR result derived from it SHALL report the sketch's configured error bound.

#### Scenario: Query compressed tail risk
- **WHEN** a quantile-based statistic is derived from a sketch-compressed node
- **THEN** the result identifies itself as approximate and includes the applicable configured error bound

### Requirement: REQ-28 Optional factor-model scenarios
Where factor-model scenario generation is enabled, the library SHALL compute a node's scenario P&L on demand from its exposure vector and the factor scenario matrix rather than require per-position scenario simulation.

#### Scenario: Generate node scenarios from factors
- **WHEN** aligned node exposures and a factor scenario matrix are supplied
- **THEN** the generated scenario vector equals the exposure-vector/factor-scenario matrix product

### Requirement: REQ-30 Optional moment-based tail estimate
Where a caller selects moment-based tail estimation instead of full scenario storage, the library SHALL derive approximate VaR from `MonoidPayload` moments alone using a Cornish-Fisher expansion and SHALL return an explicit near-Gaussian-assumption warning.

#### Scenario: Request Cornish-Fisher VaR
- **WHEN** a caller without full scenario storage opts into moment-based VaR using only sufficient `MonoidPayload` moments
- **THEN** the result is marked approximate and includes the near-Gaussian-assumption warning

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
While historical-simulation VaR is configured, advancing the historical window by one period SHALL shift the leaf scenario matrix, recombine all affected nodes bottom-up, invalidate their cached quantile results, and leave unaffected sibling subtrees unchanged.

#### Scenario: Advance a partially affected history window
- **WHEN** the leaf matrix advances from its prior historical window by exactly one period and only part of the tree is affected
- **THEN** a work trace shows affected scenario nodes recombined bottom-up, their old quantile caches invalidated, and unaffected sibling nodes neither visited nor version-changed

### Requirement: REQ-38 Fractional-depth scenario quantile
Where fractional-depth interpolation is enabled for a scenario tree, an interpolated-depth quantile SHALL interpolate quantile-function values at matching probabilities between `floor(d)` and `ceil(d)` rather than interpolate raw scenario values, and SHALL identify the result as approximate.

#### Scenario: Interpolate a scenario quantile
- **WHEN** a caller requests probability `p` at non-integer depth `d`
- **THEN** the result linearly interpolates the `p` quantiles from adjacent integer depths and reports that interpolation is approximate

### Requirement: REQ-44 Bounded scenario-node storage
Each scenario node SHALL use storage bounded by fixed scenario count `S` in exact mode or by the configured sketch compression parameter in approximate mode, independent of subtree leaf count.

#### Scenario: Grow a summarized subtree
- **WHEN** more leaves are aggregated beneath a scenario node without changing `S` or the sketch parameter
- **THEN** that node's payload storage does not grow beyond the active representation's configured bound

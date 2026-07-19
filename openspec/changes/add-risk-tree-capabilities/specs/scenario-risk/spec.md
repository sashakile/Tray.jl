## ADDED Requirements

### Requirement: REQ-6 On-demand scenario statistics
For a finite sample `x` of length `S` and probability `p` in `[0,1]`, the library SHALL define empirical quantile `q_p(x)` as sorted element `max(1, ceil(pS))`. For P&L `P`, losses SHALL be `L=-P`; at confidence `c` in `(0.5,1)`, VaR SHALL be `q_c(L)` and empirical Expected Shortfall SHALL be the quantile integral `ES_c=(1/(1-c))∫_c^1 q_u(L)du`. For sorted losses `l_(1)≤…≤l_(S)`, with `k=floor(cS)` and `r=cS-k`, this is `((1-r)l_(k+1)+Σ_{j=k+2}^S l_(j))/(S(1-c))`, including fractional boundary mass. The library SHALL derive these values on demand and store no derived statistic.

#### Scenario: Query exact tail risk
- **WHEN** a caller requests VaR, CVaR, and an arbitrary quantile from a known exact scenario vector
- **THEN** each result matches direct calculation and the node stores no quantile, VaR, or CVaR fields

#### Scenario: Reject an invalid probability
- **WHEN** quantile probability is outside `[0, 1]` or VaR/CVaR confidence is outside `(0.5, 1)`
- **THEN** calculation fails with a domain error

### Requirement: REQ-17 Component and marginal VaR
For aligned node loss vector `N` and ancestor loss vector `A` of length `S`, the library SHALL use population covariance `cov(N, A) = Σ((N_j - mean(N))(A_j - mean(A))) / S` and population standard deviation `σ_A`. For Gaussian quantile `z_c = Φ⁻¹(c)` and positive `σ_A`, it SHALL compute marginal VaR for unit node scaling as `z_c * cov(N, A) / σ_A` and component VaR at node scale `α` as `α` times marginal VaR, without storing either statistic.

#### Scenario: Derive a node contribution
- **WHEN** aligned node and ancestor scenario vectors, node scale `α`, and confidence `c` in `(0.5, 1)` are supplied and ancestor variance is positive
- **THEN** marginal and component VaR match the specified covariance formulas and no contribution statistic is stored

#### Scenario: Reject undefined node contribution
- **WHEN** vectors are misaligned, confidence is invalid, or ancestor variance is zero
- **THEN** component or marginal VaR calculation fails with an informative domain or alignment error

### Requirement: REQ-20 Scenario-matrix regeneration
When the leaf-level scenario matrix is regenerated, the library SHALL create a new immutable source epoch, rebuild affected scenario trees bottom-up, invalidate old-epoch caches, and atomically publish one new scenario epoch. It SHALL NOT require manual cache invalidation by the caller, and old and new epochs SHALL NOT combine in one query.

#### Scenario: Replace scenario inputs
- **WHEN** a new aligned scenario matrix replaces the current matrix
- **THEN** affected nodes reflect the new scenarios and cached derived statistics from prior scenarios are unavailable

### Requirement: REQ-21 Optional sketch compression
Scenario nodes SHALL use a sealed representation `Exact(values, scenario_ids, source_epoch)` or `Compressed(sketch, scenario_ids, source_epoch, config_id)`; no third state is valid. With compression threshold `N>0`, nodes with at most `N` leaves SHALL be exact and larger nodes compressed. Exact+exact SHALL add aligned values then retain or compress by threshold; exact+compressed and compressed+exact SHALL promote the exact operand with the same configuration before ordered sketch combination; compressed+compressed SHALL require identical scenario IDs, epoch, and configuration. A sketch merge MUST approximate `sketch(a+b)`, preserve scenario pairing, have an identity sketch, and satisfy associativity under a declared metric `D`: `D((a⊕b)⊕c,a⊕(b⊕c))≤ε_assoc`. Every exact-to-sketch transition MUST be reproducible from retained exact descendants or a reloadable immutable source identified by epoch; sketch-to-exact transition MUST rebuild from that source and fail atomically if unavailable. Configuration provenance (algorithm/version, parameters, rank and associativity bounds, source epoch) MUST accompany every compressed node and result.

#### Scenario: Cross the compression threshold
- **WHEN** a node in a sketch-configured `ScenarioPayload` tree summarizes more than `N` leaves
- **THEN** the node stores the configured aligned-sum sketch and remains mergeable with sketches referencing the same immutable scenario-set version and sketch configuration

#### Scenario: Retain exact storage at the threshold
- **WHEN** a node summarizes at most `N` leaves
- **THEN** the node retains its full scenario vector

#### Scenario: Preserve dependence during sketch combination
- **WHEN** two child scenario vectors have correlated values at matching scenario identifiers
- **THEN** their combined sketch approximates the distribution of elementwise sums and does not approximate the union of child distributions

#### Scenario: Reject a distribution-union sketch
- **WHEN** a configured sketch merge discards scenario pairing, as ordinary distribution-union merging does
- **THEN** sketch configuration fails the aligned-sum conformance contract

#### Scenario: Combine every representation pairing
- **WHEN** children are exact/exact, exact/compressed, compressed/exact, or compressed/compressed
- **THEN** the specified promotion path is used, provenance is preserved, and incompatible epoch/configuration combinations are rejected without mutation

#### Scenario: Transition representations
- **WHEN** threshold or configuration changes require compression or decompression
- **THEN** the node is rebuilt from retained or reloadable epoch-matched source and the transition publishes atomically, or leaves the old representation intact

### Requirement: REQ-22 Approximation error reporting
While a node uses compression, every quantile, VaR, or ES result SHALL return value, `approximate=true`, configuration provenance, and a cumulative absolute rank-error bound. Along a deterministic reduction path the bound SHALL compose as `min(1, Σ ε_promotions + Σ ε_merges + ε_query)`. ES SHALL additionally report the cumulative rank-uncertainty envelope over `[c,1]`; when finite lower and upper value envelopes are available, it SHALL integrate them into an ES value interval, and otherwise it SHALL explicitly report the value-error bound as unavailable rather than derive one from rank error alone.

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
Where a caller selects moment-based tail estimation instead of full scenario storage, the library SHALL use a `MonoidPayload` containing first through fourth power sums and transform P&L moments to loss moments using `L = -P`. It SHALL use population central moments `m_r = Σ(L_j - μ_L)^r / count`, with `σ_L = sqrt(m_2)`, skewness `γ₁ = m_3 / σ_L^3`, and excess kurtosis `γ₂ = m_4 / σ_L^4 - 3`. For `z = Φ⁻¹(c)`, it SHALL compute `z_cf = z + (z² - 1)γ₁/6 + (z³ - 3z)γ₂/24 - (2z³ - 5z)γ₁²/36` and approximate loss VaR as `μ_L + σ_L * z_cf`, and SHALL return an explicit near-Gaussian-assumption warning.

#### Scenario: Request Cornish-Fisher VaR
- **WHEN** a caller without full scenario storage opts into moment-based VaR using only sufficient `MonoidPayload` moments
- **THEN** the result uses the specified Cornish-Fisher formula, is marked approximate, and includes the near-Gaussian-assumption warning

#### Scenario: Reject insufficient tail moments
- **WHEN** fewer than four observations, missing higher-power sums, non-positive variance, or confidence outside `(0.5, 1)` is supplied
- **THEN** moment-based VaR fails with an informative domain error

### Requirement: REQ-32 Compressed-distribution disclosure
If a statistic requiring the full scenario distribution is requested from an aligned-sum-sketch-compressed node, the library SHALL return the sketch approximation with its rank-error bound and SHALL NOT represent it as exact.

#### Scenario: Request an exact median from a sketch
- **WHEN** a caller requests a median from a compressed node
- **THEN** the response contains an approximate median and rank-error bound with no exactness claim

### Requirement: REQ-36 Missing scenario data error
If VaR or CVaR is requested from a node that contains only `MonoidPayload` data and no scenario or sketch distribution, the library SHALL raise an informative error identifying the required payload capability.

#### Scenario: Request tail risk from moments-only data
- **WHEN** exact or sketch-based VaR is requested from a monoidal-only node without opting into moment estimation
- **THEN** the request fails and states that scenario or sketch data is required

### Requirement: REQ-37 Historical-window advancement
While historical simulation is configured, each immutable scenario source snapshot SHALL have a monotonically increasing `source_epoch` and each derived tree/configuration a `scenario_epoch`. A one-period advancement SHALL create a new source epoch, identify every changed immutable leaf ID, rebuild changed leaves and ancestors bottom-up, invalidate old-epoch caches, and atomically publish one new scenario epoch. Old and new epochs SHALL never combine or answer one query together.

#### Scenario: Advance a partially affected history window
- **WHEN** independently versioned source series advance by exactly one period for only a subset of leaves
- **THEN** a work trace shows affected scenario nodes recombined bottom-up, their old quantile caches invalidated, and unaffected sibling nodes neither visited nor version-changed

#### Scenario: Advance a common historical window
- **WHEN** one common window advancement changes every leaf series
- **THEN** the full scenario tree is recombined bottom-up and no unaffected sibling is assumed to exist

### Requirement: REQ-38 Fractional-depth scenario quantile
Where fractional-depth interpolation is enabled for a scenario tree, a valid focus leaf `i`, finite `d` in `[0, depth(i)]`, and probability `p` in `[0, 1]` SHALL produce an interpolated-depth quantile by applying the `REQ-6` convention at matching `p` to the two adjacent ancestor payloads, then linearly interpolating those quantiles rather than raw scenario values. The result SHALL identify itself as approximate; if either ancestor is compressed, it SHALL also carry both ancestors' provenance and the conservatively composed `REQ-22` uncertainty.

#### Scenario: Interpolate a scenario quantile
- **WHEN** a caller requests probability `p` for focus leaf `i` at non-integer depth `d`
- **THEN** the result linearly interpolates the `p` quantiles of `i`'s adjacent ancestor payloads and reports that interpolation is approximate

### Requirement: REQ-44 Bounded scenario-node storage
Each scenario node SHALL use one of the sealed `REQ-21` representations and storage bounded by fixed scenario count `S` in exact mode or by the configured sketch parameter in compressed mode, independent of subtree leaf count. Retained/reloadable reconstruction source is accounted separately and its location and epoch SHALL be configuration provenance.

#### Scenario: Grow a summarized subtree
- **WHEN** more leaves are aggregated beneath a scenario node without changing `S` or the sketch parameter
- **THEN** that node's payload storage does not grow beyond the active representation's configured bound

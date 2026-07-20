## ADDED Requirements

### Requirement: REQ-6 On-demand sample statistics
For finite sample `x` of length `S` and probability `p` in `[0,1]`, the library SHALL define `q_p(x)` as sorted element `max(1, ceil(pS))` and the upper-tail mean as `(1/(1-p))∫_p^1 q_u(x)du`, including fractional boundary mass. It SHALL derive these values on demand.

#### Scenario: Query exact sample statistics
- **WHEN** a caller requests a quantile and upper-tail mean from an exact sample
- **THEN** both match direct calculation and neither is stored in the node

### Requirement: REQ-17 Normalized covariance contribution
For aligned finite node and ancestor samples `N` and `A`, the library SHALL compute population covariance and `cov(N,A)/σ_A` when ancestor population standard deviation is positive.

#### Scenario: Derive a contribution
- **WHEN** aligned samples with positive ancestor variance are supplied
- **THEN** the result matches direct population covariance divided by ancestor standard deviation

#### Scenario: Reject undefined contribution
- **WHEN** samples are misaligned or ancestor variance is zero
- **THEN** calculation fails with an alignment or domain error

### Requirement: REQ-20 Sample-matrix regeneration
When the leaf-level aligned sample matrix is regenerated, the library SHALL create a new immutable dataset revision, rebuild affected indices bottom-up, invalidate prior-revision caches, and atomically publish the new revision. Different revisions SHALL NOT combine in one query.

#### Scenario: Replace sample inputs
- **WHEN** a new aligned sample matrix replaces the current matrix
- **THEN** affected nodes reflect only the new revision and prior derived caches are unavailable

### Requirement: REQ-21 Optional sketch compression
Sample nodes SHALL use exactly `Exact(values, sample_ids, dataset_revision)` or `Compressed(sketch, sample_ids, dataset_revision, config_id)`. A positive threshold SHALL select exact versus compressed storage. Every operand pairing SHALL preserve ordered sample alignment, revision, configuration, and deterministic combination. A sketch MUST approximate `sketch(a+b)`, preserve sample pairing, provide identity and declared associativity bounds, and be reconstructible from retained or immutable reloadable revision-matched source. Transitions and failures SHALL publish atomically; distribution-union merging is non-conforming.

#### Scenario: Combine every representation pairing
- **WHEN** children are exact/exact, exact/compressed, compressed/exact, or compressed/compressed
- **THEN** the declared promotion path preserves provenance and rejects incompatible revisions or configurations without mutation

#### Scenario: Reject a distribution-union sketch
- **WHEN** a sketch discards sample pairing
- **THEN** configuration fails the aligned-sum conformance contract

### Requirement: REQ-22 Approximation error reporting
Every compressed quantile or tail-mean result SHALL include its value, `approximate=true`, configuration provenance, and cumulative absolute rank-error bound composed as `min(1, Σ ε_promotions + Σ ε_merges + ε_query)`. A tail mean SHALL include its rank-uncertainty envelope and integrate finite value envelopes when available; otherwise value error SHALL be explicitly unavailable.

#### Scenario: Query a compressed sample
- **WHEN** a quantile or tail mean is derived from a compressed node
- **THEN** the result reports approximation provenance and conservatively composed uncertainty

### Requirement: REQ-28 Optional aligned matrix projection
Where aligned matrix projection is enabled, the library SHALL compute a length-`S` sample as row vector `w` times finite `K × S` matrix `M`, requiring exact ordered dimension-ID alignment.

#### Scenario: Project aligned values into samples
- **WHEN** aligned `w` and `M` are supplied
- **THEN** the sample equals their matrix product

#### Scenario: Reject a misaligned projection
- **WHEN** dimensions, IDs, or finiteness constraints fail
- **THEN** projection fails without a partial result

### Requirement: REQ-30 Optional moment-based quantile estimate
Where moment-based quantile estimation is selected, the library SHALL use first-through-fourth power sums, population central moments, skewness, and excess kurtosis with the documented Cornish-Fisher formula. The result SHALL be approximate and expose the near-Gaussian assumption; insufficient moments, non-positive variance, or invalid probability SHALL fail.

#### Scenario: Estimate a quantile from moments
- **WHEN** sufficient valid moments and probability are supplied
- **THEN** the result uses Cornish-Fisher, is approximate, and reports its assumption

### Requirement: REQ-32 Compressed-distribution disclosure
If a statistic requiring the full sample distribution is requested from a compressed node, the library SHALL return the sketch approximation with its error bound and SHALL NOT represent it as exact.

#### Scenario: Request a median from a sketch
- **WHEN** a caller requests a median from a compressed node
- **THEN** the response is explicitly approximate and includes rank uncertainty

### Requirement: REQ-36 Missing sample data error
If a sample-derived statistic is requested from a `ScalarSummary`-only node, the library SHALL raise an informative error identifying the required sample capability.

#### Scenario: Request a sample statistic from scalar data
- **WHEN** a caller requests a quantile without sample or sketch data
- **THEN** the request fails rather than fabricating a value

### Requirement: REQ-37 Rolling-sample advancement
While rolling samples are configured, advancing a window SHALL create a new dataset revision, identify changed immutable leaf IDs, rebuild changed leaves and ancestors, invalidate prior-revision caches, and atomically publish. A sibling SHALL remain unchanged exactly when it has no changed descendant.

#### Scenario: Advance a partially affected window
- **WHEN** only a subset of source series advance
- **THEN** only changed leaves and ancestor paths are rebuilt and no query mixes revisions

### Requirement: REQ-38 Fractional-depth sample quantile
Where fractional-depth interpolation is enabled, a valid focus leaf, finite depth, and probability SHALL produce matching quantiles at adjacent ancestors and linearly interpolate those quantiles rather than raw samples. The result SHALL be approximate and conservatively compose REQ-22 provenance when compressed.

#### Scenario: Interpolate a sample quantile
- **WHEN** a quantile is requested at non-integer depth
- **THEN** matching ancestor quantiles are interpolated and approximation is disclosed

### Requirement: REQ-44 Bounded sample-node storage
Each sample node SHALL use one REQ-21 representation with storage bounded by fixed sample count `S` or configured sketch size, independent of subtree leaf count. Reconstruction source location and dataset revision SHALL be accounted separately in provenance.

#### Scenario: Grow a summarized subtree
- **WHEN** leaf count grows without changing sample count or sketch configuration
- **THEN** sample-node storage remains within the configured bound

## ADDED Requirements

### Requirement: REQ-45 Bucketed additive attribution payload
The library SHALL provide `AttributionPayload{K}` containing a finite bucket vector of positive length `K`, a finite `realized_total`, and an immutable ordered unique bucket-ID tuple of length `K`, satisfying REQ-2's `combine` and schema-aware `identity` contract. `combine` SHALL add bucket values elementwise and add `realized_total` under REQ-3's deterministic reduction and tolerance/rebuild policy, introducing no additional tree-depth-dependent approximation. Identity SHALL contain zero buckets and zero total for the schema's bucket IDs. Mismatched lengths or non-identical bucket-ID sequences SHALL raise an alignment error consistent with REQ-33.

#### Scenario: Combine attribution payloads through multiple levels
- **WHEN** aligned attribution payloads are combined in any valid tree grouping or multi-axis rollup
- **THEN** its buckets and realized total equal direct summation of the corresponding leaf fields

#### Scenario: Reject misaligned attribution buckets
- **WHEN** two attribution payloads have mismatched bucket count or differing ordered bucket identifiers
- **THEN** combination fails with an alignment error rather than summing misaligned buckets

### Requirement: REQ-46 Bucket-sum reconciliation
Every `AttributionPayload` SHALL reconcile `sum(buckets)` with `realized_total` under REQ-3's configured numerical tolerance. The schema MAY designate one bucket ID as residual. At construction, a gap outside tolerance SHALL be added to that designated residual bucket when present; without one, construction SHALL fail. Combination preserves reconciliation because both buckets and totals are additive. The library SHALL NOT silently absorb or drop a gap.

#### Scenario: Buckets reconcile to the realized total
- **WHEN** a leaf's attribution buckets and its realized total change are both supplied
- **THEN** the sum of buckets, including any residual bucket, equals the realized total within tolerance

#### Scenario: Reject an unreconciled attribution payload
- **WHEN** buckets do not reconcile and the schema designates no residual bucket
- **THEN** construction fails with an informative reconciliation error

### Requirement: REQ-47 Declared cross-term allocation convention
Every attribution schema SHALL record an immutable attribution convention as either `Direct` for externally supplied buckets or `Allocated(method, ordered_factor_ids)` for buckets derived from simultaneously changing factors. Supported allocation methods SHALL include sequential allocation with declared factor order and symmetric allocation. The convention SHALL be configuration provenance under REQ-1 and REQ-2; if compiler-generated updates are used, REQ-A16 SHALL bind the same schema provenance. Changing convention SHALL require a new schema and Tray instance.

#### Scenario: Convention is recorded and consistent
- **WHEN** Tray is constructed with a declared direct or allocated attribution convention
- **THEN** that convention is retrievable from the schema and applies to every attribution payload in the instance

#### Scenario: Reject an undeclared convention
- **WHEN** attribution buckets are supplied without a direct or allocated convention
- **THEN** construction fails rather than silently defaulting to an unstated ordering

### Requirement: REQ-48 Ratio-safe derived metrics
Derived ratios over attribution or other additive data SHALL NOT be stored as fields or combined. The library SHALL derive a ratio at read time from additive numerator and denominator components at the queried node, depth, or multi-axis cut, following REQ-5's read-time derivation pattern.

#### Scenario: Derive a margin ratio at an arbitrary cut
- **WHEN** a caller requests a ratio at any node, depth, or multidimensional intersection with nonzero denominator
- **THEN** the result is computed from that node's additive numerator and denominator fields, not from any stored or merged ratio field

#### Scenario: Reject an undefined ratio
- **WHEN** a ratio is requested where the denominator component is zero at the queried node
- **THEN** the query fails with a domain error rather than returning a fabricated or infinite value

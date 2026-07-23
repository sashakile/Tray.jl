## ADDED Requirements

### Requirement: Finalized attribution input boundary
An attribution payload's buckets SHALL be finalized additive contributions before the payload is supplied to Tray. `Direct` and `Allocated(method, ordered_factor_ids, source_partition_id::Symbol)` SHALL record immutable provenance for that upstream construction and SHALL NOT register an executable allocation function for Tray to rerun at internal nodes or query cuts. An allocated convention's `source_partition_id` MUST be non-empty and identify the partition at which allocation was finalized. Changing that partition or rerunning allocation over aggregate driver signals requires a new externally constructed schema and dataset revision.

#### Scenario: Aggregate allocated leaf contributions
- **WHEN** a tree receives reconciled leaf bucket vectors carrying an `Allocated` convention
- **THEN** internal nodes add those vectors elementwise and never recompute allocation from aggregate driver signals

#### Scenario: Request allocation at another partition
- **WHEN** a caller needs a nonlinear allocation recomputed over a different source partition or query cut
- **THEN** the caller must compute new finalized buckets outside Tray and publish them with a new schema and dataset revision carrying the new source partition ID

#### Scenario: Reject missing partition provenance
- **WHEN** an allocated convention omits or supplies an empty source partition ID
- **THEN** schema construction fails before any attribution payload is accepted

### Requirement: Canonical residual reconciliation
For a numeric type governed by REQ-3's inexact arithmetic policy, an attribution schema MUST designate one residual bucket. The residual SHALL be derived reconciliation state and SHALL NOT be an independently additive producer coordinate. Construction SHALL preserve finite `realized_total` and all finite non-residual buckets, compute their sum in immutable schema order, and derive the residual as `realized_total - canonical_sum(non_residual_buckets)`. Internal `combine` SHALL add corresponding non-residual buckets and `realized_total`, then derive the result's residual by the same rule without summing child residuals. Arithmetic and the derived residual MUST remain finite and the resulting payload MUST reconcile within tolerance.

An exact-arithmetic schema MAY omit the residual bucket. Such construction MUST require exact equality between bucket sum and `realized_total`, and `combine` SHALL use componentwise addition. Inexact combination SHALL follow REQ-3's deterministic reduction and comparison semantics and SHALL NOT branch on accumulated child reconciliation gaps.

#### Scenario: Derive an inexact leaf residual
- **WHEN** an external leaf is constructed under an inexact schema with a designated residual bucket
- **THEN** construction preserves its total and non-residual buckets and derives the residual in schema order

#### Scenario: Canonically derive a combined residual
- **WHEN** two aligned attribution payloads with residual buckets are combined
- **THEN** the result adds totals and non-residual buckets and derives its residual without adding child residual values

#### Scenario: Reject non-finite reconciliation arithmetic
- **WHEN** finite input components overflow during summation or residual assignment would produce a non-finite value
- **THEN** construction or combination fails with a reconciliation error before publishing a payload

#### Scenario: Reject inexact schema without residual
- **WHEN** an inexact attribution schema omits its residual bucket
- **THEN** schema construction fails before accepting any payload

#### Scenario: Permit exact schema without residual
- **WHEN** an exact-arithmetic schema omits a residual and a leaf's buckets equal its realized total exactly
- **THEN** construction accepts it and componentwise combination remains exactly reconciled

## ADDED Requirements

### Requirement: Finalized attribution input boundary
An attribution payload's buckets SHALL be finalized additive contributions before the payload is supplied to Tray. `Direct` and `Allocated(method, ordered_factor_ids)` SHALL record immutable provenance for that upstream construction and SHALL NOT register an executable allocation function for Tray to rerun at internal nodes or query cuts. The producer SHALL document the source partition at which allocation was finalized; changing that partition or rerunning allocation over aggregate driver signals requires a new externally constructed dataset revision.

#### Scenario: Aggregate allocated leaf contributions
- **WHEN** a tree receives reconciled leaf bucket vectors carrying an `Allocated` convention
- **THEN** internal nodes add those vectors elementwise and never recompute allocation from aggregate driver signals

#### Scenario: Request allocation at another partition
- **WHEN** a caller needs a nonlinear allocation recomputed over a different source partition or query cut
- **THEN** the caller must compute new finalized buckets outside Tray and publish them as a new schema-compatible dataset revision

### Requirement: Construction-only residual correction
The configured residual bucket SHALL absorb an out-of-tolerance reconciliation gap only when an external leaf payload is constructed. Internal `combine` SHALL add bucket and total fields without residual correction. If deterministic internal folding produces reconciliation drift outside tolerance, the library SHALL apply REQ-3's deterministic rebuild policy or return an explicit error when rebuild source is unavailable.

#### Scenario: Correct an external leaf gap
- **WHEN** an externally supplied leaf has an out-of-tolerance gap and its schema designates a residual bucket
- **THEN** construction assigns that gap exactly once to the residual bucket before the leaf enters the tree

#### Scenario: Do not correct during merge
- **WHEN** two validated attribution payloads are combined at any internal grouping
- **THEN** every output bucket and total is the deterministic arithmetic sum of corresponding inputs with no new residual assignment

#### Scenario: Surface internal numerical drift
- **WHEN** internal arithmetic causes reconciliation to exceed the configured tolerance
- **THEN** the tree deterministically rebuilds or returns an explicit error rather than silently changing a residual bucket

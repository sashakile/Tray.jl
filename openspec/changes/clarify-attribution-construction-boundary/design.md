## Context
Tray's tree folds payloads, not arbitrary raw source records. For attribution, an upstream producer computes a reconciled bucket vector and constructs an `AttributionPayload`. The schema's `Allocated(method, ordered_factor_ids, source_partition_id)` value records that producer decision; it is not an executable aggregate allocation function.

This boundary permits nonlinear allocation methods, but their semantics are tied to the producer's chosen partition. Tray guarantees additive aggregation of the supplied contributions, not equivalence to rerunning a nonlinear method over aggregated driver signals.

Separately, the residual cannot be both an independently additive producer contribution and a correction coordinate. Leaf-only tolerance permits individually valid gaps to accumulate, while rejecting those aggregates makes `combine` partial. The residual therefore needs one role: derived reconciliation state.

## Goals / Non-Goals
- Goals:
  - Make the source-to-payload boundary unambiguous.
  - Prevent aggregate recomputation expectations for allocation provenance.
  - Preserve closed attribution combination without tolerance-triggered success or failure branches.
- Non-Goals:
  - Implement allocation algorithms or driver-signal storage in Tray.
  - Require every external allocation method to be linear.
  - Define a generic leaf-embedding API for all payload types.

## Decisions

### Allocation is finalized before payload construction
The producer supplies final additive buckets. `Allocated` records method, factor order, and a non-empty immutable `source_partition_id::Symbol`; it does not contain executable allocation logic. If users require allocation over a different partition or query cut, they must recompute from source outside the aggregation tree and construct a new schema and dataset revision.

### Residual is a derived coordinate
For numeric types governed by REQ-3's inexact arithmetic policy, the schema requires a residual bucket. External construction preserves `realized_total` and every non-residual bucket, then derives the residual as `realized_total - canonical_sum(non_residual_buckets)`. Combination adds corresponding non-residual buckets and `realized_total`, then derives the result's residual by the same rule; it never sums child residuals as independent contributions. The canonical sum follows immutable schema order. Arithmetic must remain finite and the derived result must reconcile within the schema's tolerance.

An exact-arithmetic schema may omit the residual bucket. Such leaves must reconcile exactly at construction, and combination is ordinary componentwise addition. This is closed in exact arithmetic. Under inexact arithmetic, REQ-3's deterministic reduction and comparison policy applies; canonical residual derivation removes additional tolerance-triggered control flow but does not claim IEEE addition is bitwise associative.

### Tree leaves are payloads
The generic tree contract starts at schema-valid `T` values. Domain adapters may provide constructors from raw records, but those constructors are not part of `combine`/`identity` and must document their own partition semantics.

## Risks / Trade-offs
- Existing callers that inferred aggregate allocation semantics must move that computation upstream.
- Adding `source_partition_id` changes `Allocated` construction and schema equality; migration must supply a stable identifier for the partition that produced existing buckets.
- Existing callers that treated the residual as an independently additive contribution must migrate it to a non-residual bucket or accept canonical derivation.
- Finite floating inputs can overflow under addition; this remains an explicit numeric-domain error shared by additive payloads rather than a tolerance-triggered reconciliation branch.

## Migration Plan
Clarify specs and documentation first; migrate `Allocated` schemas with a stable source partition ID; require residual configuration for inexact schemas; add canonical-residual, exact-no-residual, and non-finite arithmetic regressions; then implement one shared deterministic residual derivation path for construction and combination.

## Context
Tray's proposed convenience types are `ScalarSummary`, `SamplePayload`, and `AlignedArrayPayload`, while arbitrary lawful payload types remain first-class. Every payload implements `combine` and schema-aware `identity` and uses the same array, aggregation-index, query, concurrency, and multi-axis machinery.

Attribution and waterfall analysis require named additive buckets that reconcile with a realized total. This is distinct from sample-distribution analysis and does not use sketch machinery.

## Goals / Non-Goals
- Goals:
  - Provide `AttributionPayload{K}` as a first-class payload type.
  - Enforce bucket-sum reconciliation at construction time.
  - Require an explicit direct or allocated attribution convention per schema.
  - Derive ratio metrics (e.g., margin %) at read time, never from a stored field.
- Non-Goals:
  - Change the tree, query, concurrency, multi-axis rollup, dashboard, or incremental machinery.
  - Add a dedicated waterfall-chart dashboard widget (can be built against existing REQ-27 model).
  - Change `SamplePayload` or sketch compression.

## Decisions

### New payload type, not a tree/query change
The array, index, and query layers are operation-based over arbitrary `T`. Adding `AttributionPayload` requires no changes to the existing aggregation, query, or concurrency specs; REQ-2's operations suffice.

### Two population strategies, external to the library
Leaf bucket vectors can be produced by closed-form decomposition (e.g., partial derivatives) or by iterative revaluation (bump-and-reprice). Both strategies are external to the library — the library only aggregates whatever bucket vector it is given. No spec change is needed to accommodate either approach.

### Cross-term allocation must be declared
Externally supplied buckets use `Direct`. When multiple factors change simultaneously, sequential allocation and symmetric allocation can report different values, so `Allocated` records the method and ordered factor IDs. The convention is immutable schema provenance rather than an ambiguous default.

### Ratio-safety pattern reused from REQ-5
Derived ratios (e.g., a ratio R computed as A/B from additive fields A and B) must never be stored as a mergeable field — only their additive numerator/denominator components are stored, and the ratio is derived at read time at whatever tree depth/cut is being viewed.

### No dependency on sample machinery
Attribution buckets are deterministic decompositions of a realized total, not distributional statistics. REQ-6, REQ-17, REQ-21, REQ-22, and REQ-38 therefore do not apply.

## Risks / Trade-offs
- Reconciliation is enforced at construction; additive combination of both buckets and realized totals then preserves it.
- Attribution convention is schema provenance, not a runtime check on every `combine`. Different Tray instances can use different conventions, but one instance is consistent.

## Migration Plan
This is a greenfield addition to the set of built-in payload types. Implement in this order: payload struct and algebra, reconciliation, attribution-convention configuration, ratio derivation, then tests.

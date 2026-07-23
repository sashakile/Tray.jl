# Change: Clarify attribution construction and merge boundaries

## Why
Attribution schemas record how externally produced buckets were allocated, but the normative requirements can be read as if Tray executes the allocation method from aggregate driver signals. That interpretation makes nonlinear allocations partition-dependent even though Tray's actual role is only to aggregate finalized additive buckets.

The reconciliation contract does not define whether the residual is an independently additive producer bucket or derived reconciliation state. Treating it as both makes results grouping-dependent; rejecting accumulated child gaps instead would make `combine` partial and violate REQ-2 closure.

## What Changes
- State normatively that `Direct` and `Allocated` describe provenance for finalized leaf bucket vectors; Tray does not execute or recompute an allocation method at internal nodes or query cuts.
- Add an immutable non-empty `source_partition_id` to `Allocated` provenance.
- Define the residual bucket as a derived coordinate: construction and combination preserve `realized_total` and non-residual buckets, then derive the residual deterministically.
- Require inexact schemas to designate a residual bucket; exact schemas may omit it only when construction reconciles exactly.
- Clarify that Tray accepts constructed payload leaves; generic raw-source-to-payload embedding is outside the tree algebra contract.

## Impact
- Affected specs: `attribution-payload`, `aggregation-tree`
- Affected active changes: `add-attribution-payload`, `add-tray-capabilities`
- Affected code: attribution payload construction/combine paths and their tree/property tests
- **BREAKING**: `Allocated` construction and schema equality gain required `source_partition_id::Symbol` provenance.

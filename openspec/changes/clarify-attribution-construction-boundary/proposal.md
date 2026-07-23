# Change: Clarify attribution construction and merge boundaries

## Why
Attribution schemas record how externally produced buckets were allocated, but the normative requirements can be read as if Tray executes the allocation method from aggregate driver signals. That interpretation makes nonlinear allocations partition-dependent even though Tray's actual role is only to aggregate finalized additive buckets.

The reconciliation contract also says residual correction occurs at construction while the implementation routes internal combines through the correcting constructor. Reapplying residual correction during merges can make results grouping-dependent under floating-point drift.

## What Changes
- State normatively that `Direct` and `Allocated` describe provenance for finalized leaf bucket vectors; Tray does not execute or recompute an allocation method at internal nodes or query cuts.
- Require producers to choose and document the source partition at which an allocation is finalized.
- Restrict residual-gap assignment to external leaf payload construction.
- Require internal combination to perform elementwise addition only and use REQ-3's deterministic rebuild/error policy if reconciliation drifts outside tolerance.
- Clarify that Tray accepts constructed payload leaves; generic raw-source-to-payload embedding is outside the tree algebra contract.

## Impact
- Affected specs: `attribution-payload`, `aggregation-tree`
- Affected active changes: `add-attribution-payload`, `add-tray-capabilities`
- Affected code: attribution payload construction/combine paths and their tree/property tests

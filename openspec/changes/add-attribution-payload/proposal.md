# Change: Add Attribution Payload Capability

## Why
Bucketed-additive payloads decompose any aggregate total into named additive components. The pattern supports telemetry-source attribution, forecast-vs-actual bridges, cohort contribution, P&L attribution, and waterfalls without changing Tray's domain-neutral array, index, query, concurrency, or multi-axis machinery.

## What Changes
- Specify `AttributionPayload{K}`, a bucketed-additive payload type for decomposition of an aggregate total into named additive buckets, satisfying the same `combine`/`identity` contract as the existing built-in payloads.
- Add bucket-sum reconciliation as a construction-time invariant (explicit residual bucket for any gap).
- Add a declared direct or allocated attribution convention as schema provenance.
- Add ratio-safe derived metrics (e.g., margin %) following the read-time derivation pattern already established by `REQ-5`.

## Impact
- New capability: `attribution-payload`
- Affected specs: `attribution-payload` only; existing tree, query, multi-axis, dashboard, and incremental specs are unchanged.
- Affected code: new `AttributionPayload` struct, payload algebra, reconciliation, attribution-convention configuration, and tests.
- Affected tests: unit and property tests for payload algebra, reconciliation, alignment, attribution-convention provenance, and ratio derivation.

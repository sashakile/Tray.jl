# Implementation Status

> Last updated: 2026-07-21

## Public Behavior

| Capability | Status |
|------------|--------|
| Load the `Tray` module | ✅ Implemented and tested |
| `ScalarSummary` payload (count, sum, sumsq, min, max, + m3/m4) | ✅ Implemented and tested |
| `AttributionPayload{K}` (bucketed additive, reconciliation, convention) | ✅ Implemented and tested |
| `Tree` construction (balanced n-ary, schema validation) | ✅ Implemented and tested |
| `Tree` range query (canonical decomposition) | ✅ Implemented and tested |
| `Tree` depth-targeted range query | ✅ Implemented and tested |
| `Tree` point update (immutable, snapshot isolation) | ✅ Implemented and tested |
| `Tree` in-place update (mutable, O(n) current) | ✅ Implemented and tested |
| `Tree` root, leaf_count, depth accessors | ✅ Implemented and tested |
| `derive_mean` for ScalarSummary | ✅ Implemented and tested |
| `derive_ratio` for AttributionPayload (read-time, ratio-safe) | ✅ Implemented and tested |
| Payload conformance suite (identity laws, associativity, constant-size) | ✅ Implemented and tested |
| Custom payload support (extend `combine` + `identity`) | ✅ Implemented and tested |
| Sample analytics (quantiles, histograms) | ❌ Not started |
| Multidimensional rollups | ❌ Not started |
| Consistent sharing (binary format, cross-process) | ❌ Not started |
| Dashboard integration | ❌ Not started |
| Compiler IR incrementalization | ❌ Not started |

## Coverage by Requirement Area

| Requirement Area | Status | Requirement IDs |
|------------------|--------|-----------------|
| Aggregation tree & queries | ✅ Implemented | REQ-1–REQ-3, REQ-9–REQ-15, REQ-18–REQ-19, REQ-29, REQ-31, REQ-34, REQ-41–REQ-42 |
| Payload statistics (ScalarSummary) | ✅ Implemented | REQ-4–REQ-5, REQ-7, REQ-16, REQ-33, REQ-43 |
| Bucketed attribution / waterfalls | ✅ Implemented | REQ-45–REQ-48 |
| Sample analytics | ❌ Not started | REQ-6, REQ-17, REQ-20–REQ-22, REQ-28, REQ-30, REQ-32, REQ-36–REQ-38, REQ-44 |
| Multidimensional rollups | ❌ Not started | REQ-8, REQ-25, REQ-39 |
| Consistent sharing | ❌ Not started | REQ-23–REQ-24, REQ-26, REQ-35, REQ-40 |
| Dashboard integration | ❌ Not started | REQ-27 |
| Compiler IR incrementalization | ❌ Not started | REQ-A1–REQ-A17 |

## Active OpenSpec Changes

See [specs/index.md](specs/index.md) for active change proposals.

# Tray.jl

Tray is an ordered leaf array with a balanced aggregation index in Julia —
a domain-neutral core for incrementally maintainable aggregated views over
ordered data.

## What's Built

The current Tray implementation provides:

- **Balanced n-ary aggregation tree** — construct from leaf payloads, query by
  range or canonical decomposition, update with snapshot isolation
- **`ScalarSummary`** — built-in payload with count/sum/sumsq/min/max and
  optional higher moments (m3, m4)
- **`AttributionPayload{K}`** — built-in bucketed-additive payload with
  bucket-sum reconciliation, residual-gap assignment, and declared attribution
  conventions (direct / allocated with sequential or symmetric method)
- **Ratio-safe derived metrics** — read-time derivation via `derive_mean` and
  `derive_ratio`; never stored or combined
- **Custom payload support** — provide `combine` and `identity` for any type
- **Property-tested** — over 90 test items covering algebra, tree invariants, edge
  cases, and end-to-end workflows

## Key Concepts

- **Ordered leaves** — values retain a stable array order (1-based)
- **Balanced aggregation index** — internal nodes summarize leaf ranges via
  `combine`; queries decompose into O(log_b n) canonical nodes
- **Domain-neutral core** — aggregation is independent of application domain;
  use with numeric statistics, financial attribution, or any monoidal payload
- **Schema-bound identity** — every payload provides a schema-aware identity
  satisfying left and right identity laws

## Getting Started

```julia
using Tray

# Create a ScalarSummary tree
schema = ScalarSchema{Float64}(false)
leaves = [
    ScalarSummary(; schema, count=3, sum=6.0, sumsq=14.0, minimum=1.0, maximum=3.0),
    ScalarSummary(; schema, count=2, sum=5.0, sumsq=13.0, minimum=2.0, maximum=3.0),
    ScalarSummary(; schema, count=1, sum=10.0, sumsq=100.0, minimum=10.0, maximum=10.0),
]
tray = Tree(leaves; b=2, schema)

# Query and derive
r = range_query(tray, 1, 2)           # combine of first 2 leaves
m = derived_mean(root(tray))           # mean across all leaves

# Point update (returns new tree, preserves old)
new_leaf = ScalarSummary(; schema, count=1, sum=99.0, sumsq=9801.0, minimum=99.0, maximum=99.0)
tray2 = update(tray, 2, new_leaf)
```

## Attribution (Waterfall / Contribution Analysis)

See the [Examples page](examples.md#2-attributionpayload--waterfall--contribution-analysis)
for a full walkthrough with reconciliation, residual buckets, and allocation conventions.

## Quick Links

- [EARS Specification](generated/tray-jl-ears-spec.md) — full requirements (REQ-1..48)
- [Examples](examples.md) — walkthroughs and patterns
- [OpenSpec Changes](specs/index.md) — active change proposals
- [Implementation Status](status.md) — what's built and what's planned
- [API Reference](api.md) — auto-generated docstrings

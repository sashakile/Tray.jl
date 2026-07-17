# Tray.jl

A hierarchical aggregation library for portfolio risk analysis and scenario simulation in Julia.

```julia
using RiskTree

# Build a tree from leaf data
tree = RiskTree.build(leaves, MonoidPayload)

# Query aggregate statistics
payload = RiskTree.query(tree, 1:100, depth=3)
payload.sum  # monoidal sum
payload.mean # derived from count + sum
```

## Key Concepts

- **MonoidPayload** — mergeable statistics (count, sum, sumsq, min, max)
- **ScenarioPayload** — full P&L scenario vectors for VaR/CVaR
- **ExposurePayload** — factor exposure vectors for parametric risk
- **Groupby axes** — independent hierarchies over the same leaf data
- **LOD queries** — level-of-detail queries at configurable tree depth

## Quick Links

- [EARS Specification](specs/risk-tree-ears-spec.md) — full requirements (REQ-1..44)
- [OpenSpec Changes](specs/index.md) — active change proposals
- [API Reference](api/public.md) — public API docs
- [Implementation Status](status.md) — what's built and what's planned
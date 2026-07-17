# Tray.jl — Ubiquitous Language

## Overview

This directory defines the shared domain vocabulary for Tray.jl, a hierarchical
aggregation library for portfolio risk analysis. Every term here has a single,
unambiguous meaning. All code, docs, and conversations should use these terms
consistently.

## Bounded Contexts

| Context | File | Description |
|---------|------|-------------|
| Aggregation | `contexts/aggregation.md` | Tree structure, nodes, merge operations |
| Statistics | `contexts/statistics.md` | Payload types, derived statistics |
| Risk | `contexts/risk.md` | VaR, CVaR, parametric risk, scenario simulation |
| Query | `contexts/query.md` | LOD queries, range decomposition, interpolation |

## Core Terms

| Term | Definition |
|------|------------|
| **Node** | A vertex in the aggregation tree holding a payload and children pointers |
| **Leaf** | A node with no children, representing a single position/time bucket |
| **Payload** | Data stored per node — monoidal stats, scenario vectors, or exposure vectors |
| **Merge function** | Associative, closed binary operation `combine(a, b) :: T` |
| **LOD** | Level of detail — tree depth at which a query is answered |
| **Groupby axis** | An independent hierarchy over the same leaf data |
| **Scenario set** | A fixed, ordered set of market scenarios shared across all nodes |
| **MonoidPayload** | Mergeable statistics: count, sum, sumsq, min, max |
| **ScenarioPayload** | Dense P&L scenario vector of fixed length S |
| **ExposurePayload** | Factor exposure vector of fixed length K |

## Cross-References

- See [EARS spec](../../../risk-tree-ears-spec.md) for full requirements (REQ-1..44)
- See [OpenSpec](../../../openspec/) for change proposals

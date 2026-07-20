# Tray.jl — Ubiquitous Language

## Overview

This directory defines shared vocabulary for Tray.jl, an ordered leaf array with
a balanced aggregation index. Core terminology is domain-neutral. Application
contexts such as financial risk are optional interpretations.

## Bounded Contexts

| Context | File | Description |
|---------|------|-------------|
| Aggregation | `contexts/aggregation.md` | Array/index structure, nodes, merge operations |
| Statistics | `contexts/statistics.md` | Payload types, derived statistics |
| Query | `contexts/query.md` | LOD queries, range decomposition, interpolation |
| Financial risk (optional) | `contexts/risk.md` | Finance-specific interpretation of core samples |

## Core Terms

| Term | Definition |
|------|------------|
| **Leaf array** | Authoritative ordered storage for atomic source values and stable IDs |
| **Aggregation index** | Balanced tree whose leaves reference array slots and whose internal nodes cache summaries |
| **Node** | A vertex in the aggregation index holding a cached summary and child references |
| **Leaf ID** | Immutable identity distinct from mutable current array rank |
| **Payload** | Arbitrary value type with lawful `combine` and schema-bound identity |
| **Merge function** | Associative, closed binary operation `combine(a, b) :: T` |
| **LOD** | Level of detail — tree depth at which a query is answered |
| **Axis** | An independent hierarchy over the same immutable leaf IDs |
| **Dataset revision** | Immutable version shared by source values, axes, caches, and representations |
| **ScalarSummary** | Convenience summary containing count, sum, sumsq, minimum, and maximum |
| **SamplePayload** | Dense aligned sample vector of fixed positive length |
| **AlignedArrayPayload** | Dense vector carrying ordered immutable dimension IDs |

## Cross-References

- See the root [`tray-jl-ears-spec.md`](../../../../../tray-jl-ears-spec.md) for authoritative requirements
- See [`openspec/`](../../../../../openspec/) for change proposals

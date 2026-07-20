# Architecture

Tray is intended to pair an ordered leaf array with a balanced aggregation index.
The current package is scaffold-only; this page summarizes the proposed architecture
recorded in OpenSpec rather than implemented behavior.

## Tree Structure

The core data structure is an n-ary segment tree / hierarchical rollup, similar
to image mipmaps or OLAP rollup cubes:

- **Leaves** represent individual values in stable array order
- **Internal nodes** hold a payload computed by merging children's payloads
- **Payloads** define the values summarized by the proposed index

## Payload System

Each proposed payload type implements `combine(::T, ::T)::T` and
`identity(schema)::T`. The schema-bound identity must satisfy both left and
right identity laws for every schema-valid value.

`AttributionPayload{K}` is a proposed bucketed-additive payload for generic
contribution and waterfall analysis. It follows the same `combine` and
schema-aware `identity` contract, so it is an instance of the existing
extension pattern rather than a special-case index.

## Query & Update

- Queries decompose ranges into canonical nodes (O(log_b n))
- Updates propagate leaf changes to root (O(log_b n))
- Full construction is O(n)

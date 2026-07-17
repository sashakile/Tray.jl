# Architecture

This section documents the internal architecture of RiskTree.jl.

## Tree Structure

The core data structure is an n-ary segment tree / hierarchical rollup, similar
to image mipmaps or OLAP rollup cubes:

- **Leaves** represent individual positions or the finest time/scenario granularity
- **Internal nodes** hold a payload computed by merging children's payloads
- **Different payload types** for different statistics (monoidal, scenario, exposure)

## Payload System

Each payload type implements `combine(::T, ::T)::T` and `identity(::Type{T})::T`
to support the tree's bottom-up merge.

## Query & Update

- Queries decompose ranges into canonical nodes (O(log_b n))
- Updates propagate leaf changes to root (O(log_b n))
- Full construction is O(n)
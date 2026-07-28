# Tray.jl
[![CI](https://github.com/sashakile/Tray.jl/actions/workflows/ci.yml/badge.svg)](https://github.com/sashakile/Tray.jl/actions/workflows/ci.yml)

> **⚠ AI-Assisted Development.** This project is built through a structured Human–AI
> pair-programming workflow. Substantive changes are tracked in specifications and
> tickets, tested, reviewed with automated tools, and approved by the maintainer.
> The project has **not** had a professional security audit or human line-by-line
> review of the entire codebase.

**Tray.jl** is an ordered leaf array with a balanced aggregation index in Julia —
a domain-neutral core for incrementally maintainable aggregated views over
ordered data.

Think of it as a **persistent, queryable summary tree**: you place payloads
(any monoid) at leaf positions, and Tray maintains a balanced n-ary index that
lets you query any range in O(log_b n) canonical nodes or fold the entire tree
in O(n). Updates are immutable by default (snapshot isolation), and optional
incrementalization via compiler IR analysis can derive change recomputation
automatically.

## Key Features

- **Balanced n-ary aggregation tree** — construct from leaf payloads, range
  query, canonical decomposition, point insert/remove/update, subtree reweight
- **ScalarSummary** — built-in payload with count/sum/sumsq/min/max and
  optional higher moments (m3, m4); derived variance and standard deviation
- **AttributionPayload{K}** — bucketed-additive payload with bucket-sum
  reconciliation, residual-gap assignment, and declared attribution conventions
- **SamplePayload** — weighted sample management with multivariate projection,
  Cornish-Fisher moment quantiles, and revision-tracked regeneration
- **AlignedArrayPayload** — matrix-aligned multivariate payload with
  quadratic projection and normalized covariance contribution
- **Custom payload support** — provide `combine` and `identity` for any type;
  schema-bound identity satisfying left and right identity laws
- **SnapshotEpoch** — MVCC-like snapshot isolation with concurrent-writer
  serialization and atomic publish
- **DashboardModel** — reactive viewport model with subscribe/notify,
  latest-request-wins semantics
- **Compiler IR incrementalization** — derive change recomputation from IR
  analysis using IRTools (optional); covers pure functions and registered
  rules via RuleRegistry
- **Property-tested** — 500+ test items covering algebra, tree invariants,
  edge cases, and end-to-end workflows; Supposition.jl property tests for
  token ordering, depth correctness, and persistent update equivalence

## Quick Start

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
r = range_query(tray, 1, 2)        # combine of first 2 leaves
m = derived_mean(root(tray))        # mean across all leaves

# Point update (immutable — preserves old tree)
new_leaf = ScalarSummary(; schema, count=1, sum=99.0, sumsq=9801.0, minimum=99.0, maximum=99.0)
tray2 = update(tray, 2, new_leaf)
```

## Installation

```julia
using Pkg
Pkg.add(url="https://github.com/sashakile/Tray.jl")
```

Tray is not yet registered in Julia's General registry.

## Documentation

Full documentation is built with Documenter.jl and available in the
[`docs/`](docs/) directory. Key pages:

- [Implementation Status](docs/src/status.md) — what's built, what's planned
- [Examples](docs/src/examples.md) — walkthroughs for all major features
- [API Reference](docs/src/api.md) — auto-generated docstrings
- [EARS Specification](docs/src/generated/tray-jl-ears-spec.md) — full requirements

## Development

See [`AGENTS.md`](AGENTS.md) for workflow, conventions, and tools.

```bash
just test           # Run all tests
just test-file "..." # Run specific @testitem blocks
just ci             # Run the full CI pipeline locally
```
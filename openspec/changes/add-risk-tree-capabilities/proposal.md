# Change: Add RiskTree capability specifications

## Why
RiskTree currently has no OpenSpec capabilities describing its intended behavior. The EARS requirements in `risk-tree-ears-spec.md` need to become traceable, testable specifications before implementation begins.

## What Changes
- Specify the generic n-ary aggregation tree, canonical queries, mutations, and complexity bounds.
- Specify built-in monoidal and exposure payloads and their derived statistics.
- Specify exact and approximate scenario-risk calculations, scenario regeneration, and tail-risk behavior.
- Specify independent groupby/time axes and composed multidimensional slices.
- Specify snapshot consistency, concurrent updates, and optional cross-process shared memory.
- Specify optional dashboard model integration.
- Preserve `REQ-1` through `REQ-44` as stable traceability identifiers.

## Impact
- Affected specs: `aggregation-tree`, `payload-statistics`, `scenario-risk`, `multidimensional-rollups`, `consistent-sharing`, `dashboard-integration`
- Affected code: `src/RiskTree.jl` and new implementation modules introduced while applying this change
- Affected tests: `test/runtests.jl` and focused payload, tree, risk, concurrency, and integration tests

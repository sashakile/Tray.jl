# Change: Add RiskTree capability specifications

## Why
RiskTree currently has no OpenSpec capabilities describing its intended behavior. The [EARS requirements](../../../tray-jl-ears-spec.md) need to become traceable, testable specifications before implementation begins.

## What Changes
- Specify the generic n-ary aggregation tree, canonical queries, mutations, and complexity bounds.
- Specify built-in monoidal and exposure payloads and their derived statistics.
- Specify exact and approximate scenario-risk calculations, scenario regeneration, and tail-risk behavior.
- Specify independent groupby/time axes and composed multidimensional slices.
- Specify snapshot consistency, concurrent updates, and optional cross-process shared memory.
- Specify optional dashboard model integration.
- Define deterministic balanced topology, immutable leaf/axis identities, schema-bound payload identities, and deterministic floating-point reduction policy.
- Define sealed exact/compressed scenario states with complete promotion, provenance, epoch, reconstruction, and cumulative-error contracts.
- Make all mutations, cache/rebuild publications, and multi-node reads use one atomic snapshot boundary; define persistent copy-validate-cutover upgrades and observable complexity counters.
- Define ordered lazy actions and barriers, exact multidimensional set intersection, quantile-integral ES, affine-only interpolation, and latest-wins dashboard revisions.
- Preserve `REQ-1` through `REQ-44` as stable traceability identifiers.

## Impact
- Affected specs: `aggregation-tree`, `payload-statistics`, `scenario-risk`, `multidimensional-rollups`, `consistent-sharing`, `dashboard-integration`
- Affected code: `src/RiskTree.jl` and new implementation modules introduced while applying this change
- Affected tests: `test/runtests.jl` and focused payload, tree, risk, concurrency, and integration tests

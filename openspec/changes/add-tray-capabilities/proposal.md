# Change: Add domain-neutral Tray capability specifications

## Why
Tray currently has no OpenSpec capabilities describing its intended behavior. The [EARS requirements](../../../tray-jl-ears-spec.md) need to become traceable, testable specifications before implementation begins.

## What Changes
- Specify the generic n-ary aggregation tree, canonical queries, mutations, and complexity bounds.
- Specify built-in scalar aggregates, aligned arrays, and samples with domain-neutral derived statistics.
- Specify exact and approximate sample calculations, dataset regeneration, rolling samples, and distribution behavior.
- Specify independent groupby/time axes and composed multidimensional slices.
- Specify snapshot consistency, concurrent updates, and optional cross-process shared memory.
- Specify optional dashboard model integration.
- Define deterministic balanced topology, immutable leaf/axis identities, schema-bound payload identities, and deterministic floating-point reduction policy.
- Define sealed exact/compressed sample states with complete promotion, provenance, revision, reconstruction, and cumulative-error contracts.
- Make all mutations, cache/rebuild publications, and multi-node reads use one atomic snapshot boundary; define persistent copy-validate-cutover upgrades and observable complexity counters.
- Define ordered lazy actions and barriers, exact multidimensional set intersection, quantile-integral ES, affine-only interpolation, and latest-wins dashboard revisions.
- Preserve `REQ-1` through `REQ-44` as stable traceability identifiers.
- Isolate optional finance terminology and behavior in a separate `financial-risk` capability with `FIN-*` requirements.

## Impact
- Affected specs: `aggregation-tree`, `payload-statistics`, `sample-analytics`, `multidimensional-rollups`, `consistent-sharing`, `dashboard-integration`, `financial-risk`
- Affected code: `src/Tray.jl` and new implementation modules introduced while applying this change
- Affected tests: `test/runtests.jl` and focused payload, tree, sample, optional finance, concurrency, and integration tests

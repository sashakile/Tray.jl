# Change: Add Property-Based Testing with Supposition

## Why
Tray's payload algebra, aggregation tree, and finite-change APIs expose laws that are better exercised across generated inputs than through fixed examples alone. The current randomized tests use fixed-seed loops without shrinking, dependent generation, or shrunk counterexamples.

Supposition.jl provides the required generation and shrinking model, but its custom `SuppositionReport` is incompatible with ReTestItems result conversion when `@check` is nested inside `@testitem`. Verified experiments show that Supposition works correctly in the same `Pkg.test()` run when its checks are instead enclosed by an ordinary top-level `Test.@testset`.

## What Changes
- Add Supposition with verified baseline `0.3.5` and compatibility range `<0.4` as a test-only dependency.
- Establish a dedicated ordinary `Test.@testset` boundary for all Supposition checks; prohibit nesting `@check` inside `@testitem`, bare top-level checks, and unsupported report-introspection workarounds.
- Add a small pilot covering noncommutative tree/range ordering, exact tree depth, and persistent-update equivalence against independent reference oracles.
- Define bounded, invariant-preserving generator practices, deterministic execution, shrinking, and regression-test promotion for shrunk counterexamples.
- Document CI, coverage, ReTestItems, Testaruda, replay-database, and local test-selection behavior.
- Record the discovered `ScalarSummary` finite-change extrema inconsistency and defer its round-trip property until the append-only versus replacement semantics are resolved separately.

## Impact
- **New capability**: `property-based-testing`.
- **Affected code**: Test dependencies and test configuration only; no production dependency or production behavior change.
- **Affected tests**: Existing fixed examples remain; selected fixed-seed randomized loops may be replaced only after equivalent or stronger generated properties are proven stable.
- **Affected documentation**: Testing strategy and contributor guidance.
- **Tooling constraint**: Supposition properties run under `Pkg.test()` and coverage, but are not individually discoverable by the current Testaruda adapter.

## Dependencies
- Existing lawful `combine`, tree construction, range-query, and persistent-update behavior supply the pilot laws and reference oracles.
- Implementation is gated on approval of this proposal.
- Scalar-summary finite-change round trips remain blocked on the separate semantic decision tracked by `TRAYS-719`; they are not required for the pilot.
- Repairing the pre-existing focused-test recipe is tracked by `TRAYS-ltz` and is not required for the pilot.

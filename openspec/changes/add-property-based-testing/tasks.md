## 1. Test infrastructure and integration gate
- [ ] 1.1 Add Supposition with verified baseline 0.3.5 and compatibility range `<0.4` as a test-only dependency with no production import.
- [ ] 1.2 Add an ordinary top-level `Test.@testset` integration smoke property outside every `@testitem`; configure named checks, explicit RNG, `db=false`, and bounded examples.
- [ ] 1.3 Verify both passing and deliberately failing smoke variants through `Pkg.test()` during development, retaining only the passing variant after confirming shrunk-counterexample output and nonzero failure status.

## 2. Pilot generators and properties
- [ ] 2.1 Test-drive bounded scenario generators that construct valid dependent tree sizes, branching factors, ranges, indices, payloads, and replacements without rejection-heavy filtering.
- [ ] 2.2 Add a noncommutative sequence-payload property for exact root and range-query ordering against raw leaf/slice oracles.
- [ ] 2.3 Add an exact integer-recurrence property for tree depth and compare it with the existing approximate randomized loop before removing any redundant coverage.
- [ ] 2.4 Add a persistent-update property comparing rebuilt and updated `b`, `schema`, and `levels`, including original levels compared with a pre-update snapshot.
- [ ] 2.5 Promote every useful shrunk counterexample found during implementation into a focused ordinary regression test.

## 3. Documentation and known limitations
- [ ] 3.1 Expand contributor testing documentation with Supposition syntax, generator rules, deterministic budgets, shrinking/reproduction workflow, and regression promotion.
- [ ] 3.2 Document the mandatory ordinary-`@testset` boundary, prohibited `@testitem`/`record=false` placements, ReTestItems failure mode, and future-runner migration warning.
- [ ] 3.3 Document CI and coverage inclusion, Testaruda non-discovery, disabled example database policy, full `Pkg.test()` as the supported pilot command, unavailable individual-`@check` selection, and the `TRAYS-ltz` focused-test limitation.
- [ ] 3.4 Preserve the link to `TRAYS-719` for the `ScalarSummary` extrema round-trip inconsistency; do not add a constrained property that hides it.

## 4. Review and validation
- [ ] 4.1 Run the complete package test suite through the documented `Pkg.test()` command, formatting, and coverage/runtime comparison against the previous randomized loops.
- [ ] 4.2 Run the required Rule of 5 review, fix findings, and verify no production dependency or behavior changed.
- [ ] 4.3 Run and report `ah check --changes add-property-based-testing`, linking any contract-persistence or missing-runner findings to `TRAYS-msh`; then run `openspec validate add-property-based-testing --strict` and `git diff --check`.

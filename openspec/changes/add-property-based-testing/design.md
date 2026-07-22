## Context

Tray already expresses property-shaped contracts: two-sided payload identity, associative combination, tree-root equivalence to a direct leaf fold, range-query equivalence to a slice fold, persistent-update snapshot isolation, and finite-change identity/composition/exactness. Existing tests include fixed examples and manually randomized loops with `MersenneTwister` seeds, but those loops do not shrink failures or generate dependent constrained inputs.

Supposition.jl 0.3.5 is a Hypothesis-inspired property-testing framework with composable and dependent generators, choice-sequence shrinking, exception shrinking, and recorded-counterexample support. It supports Julia 1.8+, while Tray targets Julia 1.12.

### Verified integration behavior

The following behavior was reproduced with Julia 1.12.5, Supposition 0.3.5, and ReTestItems 1.35.2:

| Placement | Passing property | Failing property |
|---|---|---|
| `@check record=true` inside `@testitem` | ReTestItems `FieldError` on missing `SuppositionReport.results` | Infrastructure error obscures the property result |
| `@check record=false` inside `@testitem` | Invisible to the parent test result | Can exit successfully despite the failed property |
| Bare top-level `@check` | Prints a report | Does not reliably fail `Pkg.test()` |
| `@check record=true` inside ordinary `Test.@testset` | Passes normally | Reports a shrunk counterexample and fails `Pkg.test()` |
| Ordinary Supposition testset alongside existing `@testitem`s | Both execute | Both contribute correctly to the package-test result |

ReTestItems' immediate `@testitem` execution still invokes its transferable-result conversion, so the incompatibility applies even though Tray does not currently call `ReTestItems.runtests()`. Current unreleased Supposition adds statistics and counterexample accessors but does not add a public pass/fail accessor or change the custom-testset architecture. ReTestItems does not honor the generic `Test.get_test_counts` protocol in the relevant traversal.

## Goals / Non-Goals

### Goals
- Add shrinking and dependent generation for Tray's highest-value algebraic and structural laws.
- Preserve correct `Pkg.test()` failure propagation and useful shrunk counterexamples.
- Keep Supposition entirely in the test environment.
- Use independent reference oracles rather than restating implementation logic.
- Keep property execution deterministic, bounded, and suitable for required CI.
- Document the integration boundary so future test-runner restructuring does not silently break it.

### Non-Goals
- Replacing focused examples, boundary tests, or shrunk regression cases.
- Running Supposition reports through ReTestItems workers or Testaruda selection.
- Depending on unreleased Supposition `main` APIs or private report fields.
- Adding a local compatibility shim for ReTestItems internals.
- Property-testing compiler IR, world-age behavior, concurrency, or broad state-machine sequences in the pilot.
- Resolving `ScalarSummary` finite-change extrema semantics in this change.
- Treating randomized evidence as formal verification.

## Decisions

### Use Supposition with verified baseline 0.3.5 as a test-only dependency

The package is added under `[extras]`, included only in the `test` target, and bounded with `Supposition = "0.3.5"`, meaning at least the verified patch and less than 0.4. The manifest initially resolves the verified 0.3.5 release; later compatible patches require the same integration gate. Production code does not import or depend on it.

Supposition is preferred over PropCheck because it offers stronger dependent generation, choice-sequence and exception shrinking, and replay support. PropCheck is the best runner-compatible fallback but is explicitly maintenance-only. RandomizedPropertyTest and Check960 lack shrinking; JCheck is archived; the remaining Julia alternatives are dormant, broken, or generator utilities rather than complete property-testing frameworks.

### Isolate Supposition behind an ordinary Test testset

Every committed `@check` is a named property nested directly or through an included file under an ordinary top-level `Test.@testset`. It is never nested in `@testitem`. Checks use normal recording so failures reach `Pkg.test()`; `record=false` plus private report inspection is prohibited.

The property file should not use a `_test.jl` or `_tests.jl` suffix, because it intentionally contains standard testsets and must not be discovered as a ReTestItems worker file. `test/runtests.jl` includes it explicitly.

### Start with three independent-oracle properties

1. **Noncommutative root and range ordering**: a small sequence-concatenation payload checks that tree construction and `range_query` preserve exact leaf order across irregular `n`, `b`, `lo`, and `hi`. Position-distinct tokens are compared directly with the raw token vector or slice rather than folded through production `combine`, so reordering and duplication cannot be hidden.
2. **Exact depth recurrence**: repeatedly set `remaining = cld(remaining, b)` until one leaf remains and assert that the iteration count equals `depth(tree)`. This replaces floating-logarithm approximations and permissive `±1` bounds.
3. **Persistent-update equivalence**: compare the updated tree's observable `b`, `schema`, and `levels` with a rebuild from an independently copied and replaced leaf vector. Compare the original tree's levels with a pre-update snapshot rather than relying on an undefined structural `Tree == Tree` operation.

The pilot supplements existing tests first. A fixed-seed randomized loop is removed only when the new property demonstrably covers the same contract with a stronger oracle and stable runtime.

### Generate valid dependent cases by construction

Generators create a complete valid scenario rather than independently generating values and filtering most of them. They generate dimensions and schema first, then derive valid indices, ranges, leaves, and replacements. Collection sizes, branching factors, numeric magnitudes, and recursion depth are explicitly bounded.

For `ScalarSummary`, future generators should begin with raw bounded observations and derive summaries, instead of constructing field combinations that satisfy only structural validation. Floating-point associativity is not asserted over arbitrary floats; exact algebraic checks use bounded integer-valued `Float64` inputs where intermediate values remain exactly representable, or use documented approximate equality for a property that permits it.

### Use deterministic, bounded required checks

Pilot properties are named, use explicit copyable RNG seeds, disable the persistent example database initially, and cap examples and generated sizes. The initial required-CI budget is 100 examples per property with `n ≤ 32` and `b ≤ 8`; increases require measured CI cost and stable shrinking behavior.

Every valuable shrunk counterexample is promoted to an ordinary focused regression test. The property remains to search neighboring cases. Supposition's persistent database may be enabled later only after defining repository, CI-cache, concurrency, and artifact-retention policy.

### Keep normal CI authoritative and document selection limits

`Pkg.test()`, the GitHub `julia-runtest` action, and coverage execute ordinary `Test.@testset`s, so the pilot remains a required gate and contributes coverage. The configured Testaruda adapter discovers only ReTestItems `@testitem` blocks, so it cannot individually select Supposition properties. This limitation is accepted for the pilot because CI runs the complete package tests before the optional Testaruda shadow step.

The existing `just test-file` recipe references a `retest` API unavailable in the verified ReTestItems version; `TRAYS-ltz` tracks that pre-existing defect. The pilot does not add a second test environment or rely on transitive test-environment helpers merely to run one included file. Contributor documentation identifies full `Pkg.test()` as the supported local and CI command and states that individual `@check` selection is unavailable.

The repository currently ignores `.espectacular/` and configures no Espectacular runner, so generated scenario contracts cannot provide durable executable mappings in this change. `TRAYS-msh` tracks that repository-level infrastructure gap. This change still runs and reports `ah check`, but does not claim correspondence that cannot survive a clean checkout.

### Defer the ScalarSummary round-trip law

`change_between(old::ScalarSummary, new::ScalarSummary)` claims to produce a change from any old value to the new value and stores the new extrema. `apply_change`, however, computes extrema with `min(old.minimum, Δ.minimum)` and `max(old.maximum, Δ.maximum)`. It therefore cannot represent a replacement that narrows extrema, such as `[1, 10] → [2, 9]`. `TRAYS-719` tracks the required semantic decision and fix.

The property `apply_change(old, change_between(old, new)) == new` must not be constrained to hide this inconsistency. A separate decision must establish whether scalar-summary changes are append-only or support arbitrary replacement; only then should the corresponding generator and law be added.

## Risks / Trade-offs

- Supposition is pre-1.0 and its latest registered release predates current `main`; the explicit compatibility bound and use of stable APIs limit drift.
- Standard Supposition testsets are not selectable by Testaruda and cannot run through ReTestItems workers; required full-suite CI remains authoritative.
- Generator mistakes can test only an easy subdomain; scenario-by-construction generators, edge events, and review of generated examples mitigate this.
- Random floating-point laws can be false mathematically; domains and equality semantics must be explicit.
- Default high example counts can increase CI time; the pilot uses small measured budgets.
- A future migration to conventional ReTestItems-scanned files could break this arrangement; contributor documentation and an integration smoke property make the boundary visible.
- Failure replay can drift when properties, generators, or Julia versions change; shrunk examples are promoted to ordinary regression tests.
- Espectacular cannot yet persist or execute scenario mappings from a clean checkout; `TRAYS-msh` separates that infrastructure fix from this test-framework pilot.

## Migration Plan

1. Add and resolve the test-only dependency with exact compatibility metadata.
2. Add one passing integration smoke property under an ordinary `Test.@testset` and verify `Pkg.test()` reporting.
3. Add the three bounded pilot properties using shared test-only scenario generators.
4. Measure required-CI runtime and shrinking output; retain existing randomized loops until equivalence is established.
5. Update testing documentation with placement, configuration, reproduction, regression, and tooling rules.
6. Revisit ReTestItems integration only after an upstream release supports generic custom testsets or Supposition exposes a supported ordinary-result adapter.

## Open Questions

- Should a later scheduled fuzz job vary seeds and increase budgets, or should all exploration remain developer-invoked until the pilot produces useful failures?
- Should Supposition's example database eventually be committed, cached, or uploaded as a CI artifact?
- Should Testaruda gain a standard-`Test.@testset` adapter before property coverage expands beyond the pilot?
- Are `ScalarSummary` finite changes append-only, or must they represent arbitrary extrema replacement?

# Testing Strategy

## Frameworks

- **ReTestItems** for focused `@testitem`-based unit/integration tests.
- **Test** stdlib for assertions.
- **Supposition.jl 0.3.x** for property-based testing (pilot; see below).

## Test Organization

- Focused tests are in `test/runtests.jl` organized by `@testitem` blocks.
- Property-based tests are in `test/properties.jl` under ordinary `Test.@testset`
  blocks (NOT inside `@testitem` — see Property-Based Tests below).
  This file is explicitly included from `test/runtests.jl`.

## Property-Based Tests (Supposition pilot)

Tray uses [Supposition.jl](https://github.com/Seelengrab/Supposition.jl) 0.3.x
(compatibility `<0.4`) as a test-only dependency for property-based testing.

### Placement rules

- Every `@check` MUST be named and enclosed by an ordinary `Test.@testset`.
- Property tests MUST NOT be nested inside a ReTestItems `@testitem`.
- Property files MUST NOT use the `_test.jl` or `_tests.jl` suffix,
  because those patterns cause ReTestItems worker discovery.
  The current file is `test/properties.jl`, explicitly included from
  `test/runtests.jl`.
- When splitting into multiple property files, create them under
  `test/properties/` and include them from the main `test/properties.jl`
  inside the same outer `Test.@testset`. Keep shared generator types in
  `test/helpers/`.

### Why not inside @testitem?

ReTestItems 1.35.2 converts test results through its own machinery and does
not honor Supposition's custom `Test.@testset` type. Running `@check` inside
`@testitem`:

| `record` value | Behavior in @testitem |
|---|---|
| `record=true` (default) | ReTestItems raises `FieldError` on missing `SuppositionReport.results` — infrastructure error obscures property result
| `record=false` | Failure is invisible to the parent test — passes despite violations

### Running property tests

- **Local**: `just test` — runs `Pkg.test()`, which executes all `@testitem`
  blocks *and* the ordinary `Test.@testset` in `test/properties.jl`.
- **CI**: Same command via `julia-runtest` action. Failures gate CI.
- **Coverage**: Property tests contribute to coverage when run under
  `JULIA_COVERAGE=user` (included automatically with `julia-actions/julia-processcoverage`).

### Configuration

Every `@check` in the pilot uses:

- **RNG**: explicit copyable seed via `MersenneTwister` (not hardware RNG).
  Example: `rng = MersenneTwister(42)`.
- **Examples**: `max_examples = 100` — bounded for required CI.
- **Database**: `db = false` — no persistent example database during the pilot.
- **Names**: Stable property function names (e.g., `root_equals_token_vector`).

### Generator rules

- Generators construct *valid by construction* — they generate governing
  dimensions (leaf count, branching factor) first, then derive valid ranges,
  indices, and payloads. No rejection-heavy filtering.
- Bounds: n ∈ [1, 32], b ∈ [2, 8]
- Dependent values (e.g., lo ≤ hi) are enforced with min/max on the generated
  values rather than filtering.

### Shrinking and reproduction

- Supposition automatically shrinks counterexamples using choice-sequence
  shrinking. A failed property reports the minimal reproducing example.
- To reproduce a CI failure: copy the property name, seed, and shrunk
  arguments from the CI log.
- Every useful shrunk counterexample MUST be promoted to an ordinary
  focused regression test (a new `@testitem` in `test/runtests.jl`)
  while retaining the property that discovered it.

### Testaruda selection

Testaruda discovers only ReTestItems `@testitem` blocks. It CANNOT
individually select or run Supposition properties. The full `Pkg.test()`
suite runs before the optional Testaruda shadow step in CI, so property
failures still gate CI.

### Known limitations and tracking

| Issue | Description | Tracking |
|---|---|---|
| Focused test execution | `just test-file` uses `retest` API unavailable in verified ReTestItems | TRAYS-ltz |
| Espectacular contract persistence | Cannot persist or execute scenario mappings from clean checkout | TRAYS-msh |
| ScalarSummary extrema semantics | `apply_change(old, change_between(old, new)) == new` does not hold for narrowing extrema; not asserted pending decision | TRAYS-719 |

### Future-runner migration warning

If property tests are later moved into ReTestItems-scanned worker files, a
separate ordinary-`Test` execution path MUST be preserved, or support for
custom `Test.@testset` types in ReTestItems MUST first be verified. The
integration smoke property in `test/properties.jl` acts as a canary — if it
stops running or stops propagating failures, the runner boundary has broken.

## Coverage

Coverage is tracked via `julia-actions/julia-processcoverage` in CI and
uploaded to Codecov with a 50% project gate and an 80% patch target.

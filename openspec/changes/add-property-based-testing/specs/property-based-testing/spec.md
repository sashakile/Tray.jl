## ADDED Requirements

### Requirement: Test-only property framework
The project SHALL use Supposition with verified baseline 0.3.5 and compatibility range `<0.4` only as a test dependency and SHALL NOT import Supposition from production modules. Every newly resolved compatible patch SHALL pass the same integration gate before acceptance.

#### Scenario: Production package loading
- **WHEN** a user loads Tray without the test target
- **THEN** Supposition is not required, imported, or resolved as a production dependency

### Requirement: Safe test-runner boundary
Every Supposition `@check` SHALL be named and enclosed by an ordinary `Test.@testset` that is not nested inside a ReTestItems `@testitem`. Checks SHALL use normal parent recording; the suite SHALL NOT use bare top-level checks, `record=false` to suppress results, private `SuppositionReport` fields, or local ReTestItems compatibility shims to determine pass or failure.

#### Scenario: Failing generated property
- **WHEN** a generated example falsifies a Supposition property during `Pkg.test()`
- **THEN** the ordinary parent testset reports the counterexample shrunk by Supposition and the package test command exits unsuccessfully

#### Scenario: Existing test items coexist
- **WHEN** the package suite contains both existing `@testitem` blocks and the ordinary Supposition property testset
- **THEN** both execute in the same `Pkg.test()` run without passing a `SuppositionReport` through ReTestItems result conversion

### Requirement: Independent bounded property oracles
The initial property suite SHALL cover exact tree/range ordering with a noncommutative payload, exact tree depth with an integer recurrence, and persistent-update equivalence with snapshot isolation. Each property SHALL compare production behavior with an independent reference oracle and SHALL bound examples, collection sizes, branching factors, and numeric magnitude for required CI.

#### Scenario: Canonical range ordering
- **WHEN** a generated valid tree and generated inclusive range are queried
- **THEN** its position-distinct token sequence equals the raw leaf slice directly in exact left-to-right order without using production `combine` as the oracle

#### Scenario: Exact generated depth
- **WHEN** a tree is generated with positive leaf count and branching factor at least two
- **THEN** its depth equals the number of repeated `cld(remaining, b)` steps required to reduce the leaf count to one

#### Scenario: Persistent generated update
- **WHEN** a generated valid leaf index is persistently replaced
- **THEN** the updated and independently rebuilt trees have equal `b`, `schema`, and `levels`, while the original levels equal their pre-update snapshot

#### Scenario: Root ordering
- **WHEN** a valid tree is generated from position-distinct token leaves
- **THEN** the root token sequence equals the raw leaf token vector directly without using production `combine` as the oracle

### Requirement: Invariant-preserving generation and equality
Generators SHALL construct compatible dependent values by generating governing dimensions and schemas before deriving ranges, indices, leaves, and replacements. Properties SHALL avoid rejection-heavy filtering and SHALL state equality appropriate to the domain. Arbitrary floating-point associativity SHALL NOT be asserted as exact.

#### Scenario: Dependent range generation
- **WHEN** a property generates a leaf count followed by `lo` and `hi`
- **THEN** generation produces `1 ≤ lo ≤ hi ≤ leaf_count` by construction and shrinking preserves that invariant

#### Scenario: Numeric algebra generation
- **WHEN** an exact additive or associative law is tested with floating storage
- **THEN** generated values are bounded to an exactly representable domain or the property uses explicitly documented approximate equality

### Requirement: Reproducibility and regression promotion
Required properties SHALL use stable names, explicit copyable RNG seeds, bounded example counts, and no persistent Supposition database during the pilot. Every useful shrunk counterexample SHALL be added as an ordinary focused regression test while retaining the property that discovered it.

#### Scenario: Reproducing a CI failure
- **WHEN** a required property fails in CI
- **THEN** its stable property name, seed/configuration, and shrunk counterexample provide enough information to reproduce it locally and preserve it as a regression test

### Requirement: Tooling visibility and limitations
The testing documentation SHALL state that full `Pkg.test()` is the supported local and CI invocation for Supposition properties and coverage, while individual properties are not discoverable by the current Testaruda ReTestItems adapter. It SHALL state that individual `@check` selection is unavailable during the pilot. Any future move to ReTestItems-scanned worker files SHALL preserve a separate ordinary-Test execution path or first verify supported custom-testset interoperability.

#### Scenario: Required CI execution
- **WHEN** the GitHub package-test and coverage workflows execute
- **THEN** the Supposition property testset runs and its failures gate CI even though Testaruda cannot select its individual properties

### Requirement: Unresolved finite-change semantics remain visible
The property suite SHALL NOT claim that arbitrary `ScalarSummary` values satisfy `apply_change(old, change_between(old, new)) == new` until extrema-change semantics explicitly support that domain. The append-only versus arbitrary-replacement decision SHALL be tracked separately rather than hidden by constraining generated extrema.

#### Scenario: Narrowing extrema
- **WHEN** a proposed generated case changes extrema from `[1, 10]` to `[2, 9]`
- **THEN** the case remains documented as outside the current representable change contract and is not silently filtered from a claimed arbitrary round-trip property

## ADDED Requirements

### Requirement: REQ-A1 Exact finite-change algebra
For every supported value type `T`, `Tray.Incremental` SHALL define `Change{T}`, `zero_change(old)`, `valid_change(old, Δ)`, `apply_change(old, Δ)`, and `compose_change(old, Δ1, Δ2)`. Valid changes SHALL satisfy identity and sequential composition, and every generated or registered rule SHALL satisfy `apply_change(f(old_args...), Δf(old_args, old_result, Δargs)) == f(map(apply_change, old_args, Δargs)...)` under documented equality semantics.

#### Scenario: Identity, composition, and exactness
- **WHEN** valid changes are generated for a supported type and function
- **THEN** zero leaves the old value unchanged, composition equals sequential application, and the finite-change exactness equation holds

### Requirement: REQ-A2 Internal IR-provider interface
Derivation SHALL use an internal IR-provider interface for capability probing and IR retrieval. The default optional provider SHALL use documented IRTools `IR`, `code_ir`, and `@code_ir` surfaces and support only matrix-listed Julia versions 1.10 or newer. The v1 CI matrix SHALL contain Julia 1.10.x, 1.11.x, and 1.12.x rows, each with an exact compatible IRTools 0.4.x patch pinned in its manifest; a later Julia minor SHALL NOT be declared supported until its pinned row passes.

#### Scenario: Retrieve through the default provider
- **WHEN** `derive(f, argtypes)` runs in a matrix-supported environment
- **THEN** the provider returns typed Julia IR for the uniquely selected method without direct dependence on `Core.Compiler.IRCode` internals

### Requirement: REQ-A3 Exact generated update function
The system SHALL generate `Δf` only when all transitively reachable operations are covered and SHALL enforce the REQ-A1 law for valid changes. A generated artifact SHALL never be presented as a derivative or approximation.

#### Scenario: Multiplication includes finite cross term
- **WHEN** `f(x,y)=x*y` uses additive numeric changes
- **THEN** `Δf` returns `old_x*Δy + Δx*old_y + Δx*Δy` and applying it equals multiplication of the changed inputs

#### Scenario: Nonlinear sine is exact
- **WHEN** `f(x)=sin(x)` is covered
- **THEN** its rule returns `sin(apply_change(old_x,Δx))-sin(old_x)` rather than `cos(old_x)*Δx`

### Requirement: REQ-A4 Revisioned rule registry
The registry key SHALL be `(typeof(f), Tuple{argtypes...})`. Lookup SHALL follow Julia-like applicability and specificity: no applicable key is missing, one uniquely most-specific key wins, and incomparable most-specific keys are ambiguous. Snapshots SHALL be immutable and monotonically revisioned; duplicate registration SHALL reject unless explicit replacement is requested, and removal SHALL name an exact key and create a new revision.

#### Scenario: Specific lookup and ambiguity
- **WHEN** applicable registrations are compared for a full callable type and argument tuple
- **THEN** the unique most-specific rule is returned or a classified ambiguity is returned without arbitrary tie-breaking

#### Scenario: Duplicate, replace, and remove
- **WHEN** an exact key is duplicated, explicitly replaced, or exactly removed
- **THEN** duplication rejects while replacement and removal publish new immutable revisions without changing prior snapshots

### Requirement: REQ-A5 Sealed transitive analysis result
`AnalysisResult` SHALL be a sealed sum type containing only `Derived(artifact, coverage)` and `Rejected(diagnostics, coverage)`. Every derivation-time failure classified by REQ-A11, including unavailable or incompatible providers, SHALL be represented as a typed diagnostic inside `Rejected`; no third result state or thrown raw provider/compiler failure is permitted. Coverage SHALL use the transitive lattice `Covered < Boundary < Rejected`, joining to the worse state across every reachable callee. `Rejected` SHALL contain no callable partial artifact.

#### Scenario: Transitive boundary rejects generation
- **WHEN** a reachable callee contains a boundary despite all local operations being covered
- **THEN** analysis joins to at least `Boundary` and returns `Rejected` with no callable artifact

### Requirement: REQ-A6 Exact built-ins and core baselines
Built-in rules SHALL obey REQ-A1. `min` and `max` SHALL compute old and changed results using Julia operation semantics and encode the change from `old_result` to `new_result`, including deterministic argument-order ties, signed zero, NaN, infinities, and other non-finite values. Validation SHALL cover MonoidPayload, ScenarioPayload, and ExposurePayload against lawful canonical `combine` and full bottom-up recomputation.

#### Scenario: Min and max crossing, ties, and non-finite values
- **WHEN** valid changes alter ordering or inputs include ties, signed zero, NaN, or infinities
- **THEN** applying the rule's result to `old_result` equals direct Julia `min` or `max` on changed inputs, or the type is explicitly rejected when exact change/equality semantics are unavailable

#### Scenario: All core payload baselines
- **WHEN** generated updates are exercised for MonoidPayload, ScenarioPayload, and ExposurePayload
- **THEN** each result equals its canonical `combine` full-recompute oracle under the payload's documented equality semantics

### Requirement: REQ-A7 Canonical combine and common strategy adapter
Lawful `combine` SHALL remain the canonical operation. `Δf` SHALL be only an optional optimization selected through one common update-strategy adapter that receives immutable old child, sibling, parent, and result snapshots and retains canonical recomputation as the oracle and fallback.

#### Scenario: Optimization is observationally optional
- **WHEN** a generated strategy is unavailable, rejected, stale, or fails validation
- **THEN** the same adapter uses canonical `combine` and produces the full-recompute result

### Requirement: REQ-A8 V1 program boundary
V1 SHALL support pure, effect-free straight-line programs and branch-stable programs, where old and changed inputs follow identical control-flow edges. Changed control flow, dynamic calls, recursion, loops outside an explicitly unrolled fixed-shape subset, exceptions, mutation, aliasing, global reads or writes, RNG, I/O, tasks, atomics, and `ccall` SHALL be trace boundaries and SHALL trigger rejection or canonical fallback.

#### Scenario: Branch remains stable
- **WHEN** old and changed inputs take the same covered branch
- **THEN** the generated update may execute and remains subject to the exactness law

#### Scenario: Effect or control boundary
- **WHEN** analysis or execution encounters any listed effect or changed branch
- **THEN** it returns a classified boundary and no partial generated result is published

### Requirement: REQ-A9 Atomic ancestor-path updates
Generated ancestor-path updates SHALL be computed in private state and the complete validated path SHALL be published atomically as the same snapshot transaction required by REQ-23. On any boundary, stale artifact, exception, or oracle mismatch, private results SHALL be discarded and the path SHALL be recomputed with canonical `combine` before that transaction publishes.

#### Scenario: Mid-path generated failure
- **WHEN** a generated update fails after one or more private ancestor results are computed
- **THEN** no partial ancestor state is visible and canonical recomputation is atomically published

### Requirement: REQ-A10 No silent approximation
The system SHALL NOT fabricate approximate rules. Rank-order operations such as `sort`, `sortperm`, `median`, and `quantile` SHALL be described as inefficient without explicit maintained state or a registered exact/bounded rule, not impossible in principle, and SHALL be boundaries by default.

#### Scenario: Unregistered rank operation
- **WHEN** derivation reaches an unregistered rank-order operation
- **THEN** it rejects generation and suggests canonical recomputation, an explicit rule, or a suitable mergeable sketch

### Requirement: REQ-A11 Classified call-time failures
Public failures SHALL be classified as `UnsupportedEnvironment`, `IRProviderUnavailable`, `IRProviderIncompatible`, `MethodMissing`, `MethodAmbiguous`, `RuleMissing`, `RuleAmbiguous`, `UnsupportedEffect`, `ControlFlowChanged`, `MutableCapture`, `StaleArtifact`, `InvalidChange`, `OracleMismatch`, or `GenerationFailure`. Each SHALL carry phase, known callable/method identity, known source location, remediation, and preserved cause. Environment and provider checks SHALL occur at `derive` call time, never module initialization.

#### Scenario: Provider incompatibility
- **WHEN** derivation runs with an incompatible provider or Julia/IRTools pairing
- **THEN** `derive` returns the corresponding classified call-time error naming versions and remediation while module loading remains successful

### Requirement: REQ-A12 No LLVM-level incrementalization
`Tray.Incremental` SHALL NOT implement an LLVM-level pass or depend on Enzyme-style transformation.

#### Scenario: Dependency audit
- **WHEN** incrementalization dependencies are audited
- **THEN** no LLVM-level transformation dependency is required by this capability

### Requirement: REQ-A13 No differential-dataflow binding
`Tray.Incremental` SHALL NOT reimplement or bind to differential-dataflow or timely-dataflow; recursive and iterative dataflow remains outside this change.

#### Scenario: Runtime audit
- **WHEN** runtime and binary dependencies are audited
- **THEN** no differential-dataflow, timely-dataflow, or associated FFI binding is present

### Requirement: REQ-A14 Memoization interoperability
Generated artifacts SHALL be plain callable values that may be wrapped by external memoization without coupling Tray to a memoization framework, subject to normal artifact validation on every invocation.

#### Scenario: External cache wrapper
- **WHEN** an external memoization layer invokes a generated artifact
- **THEN** invocation succeeds only after the same staleness checks as an unwrapped invocation and requires no special integration hook

### Requirement: REQ-A15 Covered broadcast lowering
Broadcast and fused dot calls SHALL be supported only when their shape is fixed for the update and every lowered element operation is transitively covered; otherwise they SHALL be boundaries.

#### Scenario: Fixed-shape covered broadcast
- **WHEN** old and changed arrays retain shape and every fused element operation has an exact rule
- **THEN** the generated update satisfies REQ-A1 elementwise and for the aggregate result

### Requirement: REQ-A16 Reproducible artifact identity
Every generated artifact SHALL bind its method instance and valid world range, full argument types, immutable closure-capture snapshot, registry revision, provider identity/version, Julia/backend/toolchain identity, and payload schema/version. Mutable captures SHALL reject. At invocation, any mismatch or expired world SHALL fail closed and cause rederivation or canonical fallback.

#### Scenario: Artifact becomes stale
- **WHEN** any bound identity differs at invocation
- **THEN** no generated code runs and the system returns `StaleArtifact` before rederiving or using canonical `combine`

#### Scenario: Mutable closure capture
- **WHEN** derivation discovers a mutable captured value
- **THEN** it returns `MutableCapture` and produces no artifact

### Requirement: REQ-A17 Graceful operation without IRTools
IRTools SHALL remain optional. Its availability and capability SHALL be probed only by `derive`. Module loading, registry registration/lookup, and invocation of a non-stale pre-existing generated artifact SHALL remain usable without importing or probing IRTools; artifact validation SHALL compare stored provider identity metadata without loading the provider. A derivation attempt without IRTools SHALL return `Rejected` containing `IRProviderUnavailable` with installation guidance.

#### Scenario: Derive and invoke without IRTools
- **WHEN** IRTools is absent
- **THEN** derivation fails at call time with installation guidance while registry operations and valid pre-existing generated artifacts continue normally

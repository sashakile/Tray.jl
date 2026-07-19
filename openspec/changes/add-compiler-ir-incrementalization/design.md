## Context

The optimization computes exact finite changes, not derivatives. The change-action account in Cai, Giarrusso, Rendel, and Ostermann's “A Theory of Changes for Higher-Order Languages” is related and analogous; it does not establish this implementation's correctness. Correctness comes from the finite-change law and full-recompute oracle.

## Goals / Non-Goals

### Goals
- Preserve lawful `combine` as canonical and make generated `Δf` an optional optimization.
- Support pure, effect-free straight-line and branch-stable programs in v1.
- Fail closed with reproducible artifacts and classified diagnostics.

### Non-Goals
- Changed control flow, dynamic calls, recursion, general loops, exceptions, mutation, aliasing, globals, RNG, I/O, tasks, atomics, or `ccall`.
- LLVM-level transformation, differential-dataflow bindings, or replacement of canonical `combine`.
- Claims that rank operations are impossible to incrementalize; without explicit state/rules they are merely inefficient and therefore boundaries in v1.

## Decisions

### Finite-change algebra
Each supported value type `T` defines `Change{T}`, `zero_change(old::T)`, `valid_change(old, Δ)::Bool`, `apply_change(old, Δ)::T`, and `compose_change(old, Δ1, Δ2)::Change{T}`. Valid changes satisfy identity and sequential composition. Every rule satisfies `apply_change(f(old_args...), Δf(old_args, old_result, Δargs)) == f(map(apply_change, old_args, Δargs)...)` for valid changes, under the operation's documented equality semantics.

### Rules and immutable registry snapshots
The key is `(typeof(f), Tuple{argtypes...})`, including the complete callable type and argument tuple. Lookup uses Julia-like applicability and specificity; zero matches means uncovered and incomparable most-specific matches mean ambiguity. Registration is duplicate-rejecting by default, explicit replacement creates a new immutable monotonically numbered revision, removal must name the exact key and also creates a revision, and derived artifacts retain their revision snapshot.

### Exact built-ins
For additive numeric changes, multiplication returns `old_x*Δy + Δx*old_y + Δx*Δy`. `sin` returns `sin(apply_change(old_x, Δx)) - sin(old_x)`, not a linearization. `min`/`max` compute `new_result = op(apply_change(old_x,Δx), apply_change(old_y,Δy))` and return the change from `old_result` to `new_result`; they use Julia's operation semantics, including deterministic argument-order ties, signed zero, NaN, and other non-finite values. Unsupported equality/change representations reject rather than approximate.

### Analysis and generation
`AnalysisResult` is a sealed sum type: `Derived(artifact, coverage)` or `Rejected(diagnostics, coverage)`. Every classified derivation failure is a typed diagnostic inside `Rejected`; raw provider/compiler failures are preserved only as causes, not thrown as a third result channel. Coverage is the transitive lattice `Covered < Boundary < Rejected`; joins take the worse value and include every reachable callee. `Rejected` contains no callable partial artifact. A derived artifact is callable only after all transitive sites are `Covered`.

### Update strategy
One adapter selects canonical recomputation or an optional generated update. It supplies immutable snapshots of old child, sibling, parent, and result state. Every generated result is checked against a full bottom-up canonical-recompute oracle in validation/testing modes. Ancestor-path changes are computed privately; the complete path is atomically published in the core REQ-23 snapshot transaction only after success and validation. Any staleness, boundary, exception, or validation failure discards private results and recomputes with canonical `combine` before publication.

### Scope and artifacts
Branch-stable means old and changed inputs select the same control-flow edges; otherwise the call falls back. Fixed-shape loops may be explicitly unrolled by a provider; all other loops are boundaries. Artifacts bind method instance and world range, full argument types, immutable closure snapshot, registry revision, IR-provider identity/version, Julia/backend/toolchain identity, and payload schema/version. Mutable captures reject. Call-time mismatch or expired world validity fails closed and triggers rederivation or canonical fallback.

### IR provider and compatibility
An internal provider interface exposes capability probing and IR retrieval. The default provider uses documented IRTools `IR`, `code_ir`, and `@code_ir` surfaces only. Julia 1.10 is the minimum eligible version, but only explicit matrix rows are supported. V1 tests Julia 1.10.x, 1.11.x, and 1.12.x, each with an exact IRTools 0.4.x patch pinned in that CI job's manifest; adding a Julia minor requires adding and passing a pinned matrix row first. Capability probing occurs only at `derive`; module loading, registry operations, and existing generated artifacts do not import or probe IRTools, and artifact validation compares stored provider metadata. REQ-A11 compatibility errors and REQ-A17 absence errors are typed diagnostics in `Rejected` and therefore agree on call-time behavior.

### Classified errors
Public failures are typed as `UnsupportedEnvironment`, `IRProviderUnavailable`, `IRProviderIncompatible`, `MethodMissing`, `MethodAmbiguous`, `RuleMissing`, `RuleAmbiguous`, `UnsupportedEffect`, `ControlFlowChanged`, `MutableCapture`, `StaleArtifact`, `InvalidChange`, `OracleMismatch`, or `GenerationFailure`. Each carries phase, callable/method identity when known, source location when known, and remediation; raw provider/compiler exceptions are preserved as causes.

## Risks / Trade-offs
- Compiler and world-age drift can invalidate code; complete artifact identity and fail-closed checks mitigate it.
- Exact recompute-difference rules can be less efficient; correctness takes priority and canonical recomputation remains available.
- Restrictive v1 coverage rejects useful programs; boundaries are explicit and can be expanded without weakening the contract.

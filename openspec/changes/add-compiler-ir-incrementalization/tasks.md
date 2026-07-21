## 1. REQ-A1–A3: algebra, provider, and generation
- [x] 1.1 Implement and law-test per-type `Change`, zero, validity, apply, composition, and exact `Δf` contract.
- [x] 1.2 Implement the internal IR-provider interface and IRTools default using `IR`, `code_ir`, and `@code_ir`.
- [x] 1.3 Generate only from transitively covered, pure straight-line or branch-stable IR.

## 2. REQ-A4–A5: registry and analysis
- [x] 2.1 Implement full callable-type/argument-tuple keys, Julia-like specificity and ambiguity, immutable revisions, duplicate rejection, explicit replacement, and exact-key removal.
- [x] 2.2 Implement sealed `AnalysisResult = Derived | Rejected` and transitive `Covered < Boundary < Rejected` joins; ensure rejection exposes no callable artifact.

## 3. REQ-A6: exact rules and baselines
- [x] 3.1 Implement exact addition, multiplication including the cross term, recompute-difference `sin`, and old/new-result `min`/`max` rules with ties and non-finite tests.
- [x] 3.2 Validate domain-neutral scalar-summary, aligned-array, sample, and user-defined fixtures against canonical `combine` and full recomputation; keep optional adapters out of compiler conformance.

## 4. REQ-A7–A10: strategy and boundaries
- [x] 4.1 Implement one update-strategy adapter retaining canonical `combine`, immutable old child/sibling/parent snapshots, and a full-recompute oracle.
- [x] 4.2 Detect changed branches and every specified effect/control boundary; classify and fall back without publishing partial state.
- [x] 4.3 Compute ancestor paths privately and atomically publish only complete validated results; otherwise use canonical `combine`.

## 5. REQ-A11–A17: compatibility and lifecycle
- [x] 5.1 Bind artifacts to method instance/world, argument types, immutable closure snapshot, registry revision, provider, backend/toolchain, and payload schema; reject mutable captures and fail closed when stale.
- [x] 5.2 Implement classified public errors with causes, locations, phases, and remediation.
- [ ] 5.3 Test the explicit Julia ≥1.10/IRTools compatibility matrix and derive-time-only capability probe; test registry and generated artifact use without IRTools.
- [x] 5.4 Test non-goals, memoization wrapping, and covered broadcast behavior for REQ-A12–A15.
- [x] 5.5 Add requirement-to-test traceability for exactly REQ-A1 through REQ-A17.
- [ ] 5.6 Run tests, `ah check --changes add-compiler-ir-incrementalization`, strict OpenSpec validation, and `git diff --check`.

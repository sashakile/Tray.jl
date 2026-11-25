## ADDED Requirements

### Requirement: Toolchain-gated Lean lane
The project SHALL provide a `just lean` recipe that builds the Lean twin, runs
the parity oracle, and runs the axiom audit, and `just ci` SHALL NOT depend on
it. The Lean toolchain SHALL be pinned by a committed `lean/lean-toolchain`
file and provisioned separately via elan. Any future CI attachment SHALL be an
opt-in lane, never a gate every checkout must satisfy.

#### Scenario: Fresh checkout without elan
- **WHEN** a contributor with only the Julia toolchain runs `just ci`
- **THEN** the recipe succeeds without invoking lake, elan, or any Lean binary

#### Scenario: Lean lane on demand
- **WHEN** a contributor with elan and the committed pin runs `just lean`
- **THEN** the twin builds, the parity oracle runs, the axiom audit runs, and a
  failure in any stage fails the recipe

### Requirement: Standard-library kernel twin
The `lean/` Lake package SHALL re-implement the deployed kernel semantics —
ordered leaves, a monoid payload interface (`combine`, `identity`), whole-tree
fold, inclusive range query, and persistent leaf replacement — using the Lean
standard library only. The package SHALL NOT depend on Mathlib or any external
Lake dependency, SHALL NOT import production Julia code, and SHALL keep the
executable harness separate from the kernel modules.

#### Scenario: Twin mirrors a fixture
- **WHEN** the twin evaluates a committed fixture's leaf vector, range, and
  replacement
- **THEN** its root fold, range result, and post-replacement fold are computed
  by the twin's own definitions without calling Julia

#### Scenario: Dependency discipline
- **WHEN** the package manifest is inspected
- **THEN** the only declared dependency is the pinned Lean toolchain and the
  kernel modules import no module outside the Lean standard library

### Requirement: Proved kernel theorems with hypothesis-discharged laws
The proof modules SHALL prove, as total theorems: the monoid laws for each shipped payload instance, range-query equivalence, and incremental-maintenance equivalence. Monoid laws SHALL appear only as explicit theorem hypotheses discharged per instance and SHALL NOT be declared as Lean axioms. No theorem may assume `combine` commutes.

#### Scenario: Range query equals naive recomputation
- **WHEN** the query-equivalence theorem is applied to any payload instance
  with its proved laws
- **THEN** the range query over `lo ≤ hi` equals the left-to-right
  `foldl combine identity` recomputation over that leaf slice

#### Scenario: Incremental update equals canonical fold
- **WHEN** a leaf is persistently replaced in the twin's tree
- **THEN** the theorem establishes the updated cached fold equals the canonical
  fold of the entire new leaf vector

### Requirement: Machine-checkable axiom audit
A committed audit script SHALL fail unless every public theorem's
`#print axioms` output lists only axioms from the allowlist
`{propext, Classical.choice, Quot.sound}` (or none), no build output contains a
`sorry` warning, no twin source declares `axiom`, and no output line matches an
unexpected shape. The audit SHALL print the offending declaration for any
violation and SHALL be part of the `just lean` lane.

#### Scenario: Unfinished proof fails the gate
- **WHEN** a theorem body contains `sorry` and the audit runs
- **THEN** the audit reports `sorryAx` (or the `sorry` build warning) for that
  declaration and exits nonzero

#### Scenario: Hidden assumption fails the gate
- **WHEN** a twin module declares a user `axiom` and the audit runs
- **THEN** the audit reports the file and line of the declaration and exits
  nonzero

### Requirement: Parity oracle with strict exit-code discipline
A `tray-parity` oracle executable SHALL enumerate the committed JSON fixture corpus and compare each fixture's root, range, and post-replacement results between the Lean twin and the Julia implementation (via a committed emitter script). It SHALL exit 0 on full agreement, exit 1 only on genuine semantic divergence, and exit 2 on harness failures, and harness failures SHALL never be reported as divergence.

#### Scenario: Detecting implementation drift
- **WHEN** a fixture's Julia-emitted range result differs from the twin's
- **THEN** the oracle exits 1 and names the fixture with both disagreeing
  values

#### Scenario: Broken fixture is a harness failure
- **WHEN** a corpus file is not valid fixture JSON
- **THEN** the oracle exits 2 with a harness-error message and does not report
  a semantic divergence

### Requirement: Integer-encoded fixture corpus
The parity corpus SHALL carry natural-number and token-list payloads only; Float64 payloads SHALL be excluded until a float-serialization design decision exists. Fixture magnitudes SHALL stay inside Julia's `Int64` wraparound range, every fixture SHALL be production-legal (nonempty leaves, `1 ≤ lo ≤ hi ≤ n`), and range fixtures SHALL use default full-depth queries (`target_depth = nothing`).

#### Scenario: Corpus legality mirrors production contract
- **WHEN** a fixture is emitted or hand-authored
- **THEN** its leaves are nonempty, its range satisfies `1 ≤ lo ≤ hi ≤ n`, and any divergence reported for it is a semantic comparison, never a rejected-input mismatch

#### Scenario: No float payloads in the corpus
- **WHEN** the emitter would serialize a Float64 payload result
- **THEN** the corpus schema rejects it as a harness error until a float-serialization design decision extends the contract

### Requirement: Kernel-only scope boundary
The twin SHALL model only the kernel surface: monoid payload interface, ordered
leaves, tree fold, range query, and persistent single-leaf replacement.
Dashboards, persistence/serialization, financial-risk adapters, concurrent
snapshot publication, and performance characteristics SHALL be out of scope;
extending the twin's scope SHALL require a proposal amendment, not a silent
addition. Performance claims SHALL remain the benchmark suite's responsibility.

#### Scenario: Out-of-scope kernel change
- **WHEN** production changes semantics outside the kernel surface
- **THEN** no twin, proof, or parity update is required, and the existing
  corpus still passes

#### Scenario: In-scope kernel change
- **WHEN** production changes kernel semantics (payload interface, leaf
  ordering, fold, range, replacement)
- **THEN** `just lean` surfaces the divergence and updating the twin plus
  corpus is part of landing that change

# Design: Lean Assurance Twin

## Context
Tray.jl's correctness claims are empirical today. Catherine (Rust, same
workstation) runs a proven Lean 4 twin architecture: `lean/` Lake package,
`lean-parity` oracle, `check-lean-axioms.sh` audit, elan-gated `just lean`
lane outside `just ci`. This design transfers that architecture to a Julia
host, which no Rust-native verifier (Kani, Verus) could.

## Goals
- Total, machine-checkable proofs of the kernel's semantic claims.
- A drift tripwire between twin and implementation.
- Zero impact on checkouts without elan.

## Non-Goals
- Proving performance (benchmarks stay the instrument for the 5× claim).
- Modeling concurrency/snapshot publication (`TRAYS-ol9`).
- Covering dashboards, persistence, financial risk, or Julia runtime semantics
  (garbage collection, world age, dispatch).

## Decisions

### Decision 1 — Twin, not extraction
The Lean twin re-implements kernel semantics **from the deployed specs**, not
by translating Julia source. There is no Julia→Lean extraction toolchain, and
catherine's experience shows the parity oracle is what keeps an independent
twin honest: a semantic divergence between twin and implementation is a
first-class CI signal, not silent drift.

*Alternative rejected*: proof-carrying annotations embedded in Julia — no
verifier exists to check them; they would be decoration.

### Decision 2 — Standard library only, pinned toolchain
No Mathlib. The twin needs only `List`, `Nat`, structure declarations, and
tactic proofs; Mathlib would multiply build time and pull the twin toward
general mathematics instead of Tray semantics. The committed
`lean/lean-toolchain` pin (Lean 4.36, matching the provisioned elan default)
makes builds reproducible.

### Decision 3 — Monoid laws as hypotheses, never axioms
The kernel theorems are stated **parametrically over any payload** satisfying
its laws: the associativity and identity laws appear as explicit hypotheses of
`rangeQuery_eq_naive`-shaped theorems. Hypotheses are discharged at each
concrete instance (token payload, additive payload), so the axiom audit still
passes with only the classical allowlist. This covers arbitrary future schemas
without re-proving the tree theorems, and it mirrors the noncommutative reality:
nothing may assume `combine` commutes.

Direction note: under associativity both fold directions agree, so the
canonical statement uses the left-to-right `foldl combine identity` form,
matching the proposal's "naive left-to-right recomputation" framing and
Julia's left-to-right `reduce` chunk order (`src/core.jl:71`).

*Alternative rejected*: declaring a `Monoid` type class with law *axioms* —
the axiom audit would rightly reject it as unproved assumption.

### Decision 4 — Parity exit-code discipline
`tray-parity` exits 0 on agreement, 1 only on a genuine semantic divergence
(twin result ≠ Julia result for the same fixture), and 2 on harness failures
(bad JSON, missing emitter, spawn errors). Harness failures never masquerade
as divergence; only exit 1 or 2 fail the gate, with distinct messages. The
corpus is committed JSON under `lean/fixtures/`, emitted and re-emitted by a
small Julia script (`scripts/emit-parity-fixtures.jl`) so corpus refreshes are
mechanical.

### Decision 5 — Elan-gated lane outside `just ci`
`just lean` (build → parity → audit) is not a dependency of `just ci`. A
fresh checkout with only Julia passes CI unchanged; contributors touching the
kernel or twin run `just lean` locally, and the lane may later be attached to
lefthook's pre-push exactly as catherine does. This mirrors how catherine
treats its Kani lane.

### Decision 6 — Proof targets track runtime oracles
`src/incremental.jl` already treats canonical `reduce(combine, …)` as its
runtime oracle; the twin promotes that same judgment to a static theorem. Each
proof target becomes one beads issue with a red→green shape: theorem stated
with `sorry` (build warns, audit fails) is red; landed proof turning the audit
green closes the issue.

### Decision 7 — Integer-encoded fixture corpus
The parity corpus carries natural-number and token-list payloads only; Float64
payloads are excluded until a float-serialization design decision exists.
Catherine's twin made the same move — its JSON projection reads Nat fields
only (`Lean.Json.getNat?`). Magnitudes stay bounded so Julia's `Int64` cannot
wrap against the twin's unbounded `Nat`, and fixtures are production-legal
only (nonempty trees, `1 ≤ lo ≤ hi ≤ n`, `target_depth = nothing`), since
rejected inputs are production contract, not parity comparisons.

*Alternative rejected*: exact Float64 round-trip parity now — Julia's
shortest-decimal formatting versus Lean's float parsing would need a dedicated
correctness argument before the gate could be trusted on the value
proposition's primary payload type.

## Risks / Trade-offs
- **Twin maintenance**: every kernel semantic change requires a twin update.
  Mitigation: the parity oracle makes drift loud at the next `just lean`.
- **Scope creep**: proof effort could balloon toward the whole package.
  Mitigation: the scope-boundary requirement names the kernel surface; extending
  it requires a proposal amendment.
- **Toolchain availability**: proofs gate on elan, not CI. Accepted: kernel
  changes are rare and reviewable; the risk profile matches catherine's.

## Migration Plan
Additive only. `lean/`, `scripts/`, one justfile recipe, docs section. Nothing
existing moves or changes behavior. Rollback is deleting the new paths.

## Open Questions
- None blocking. Fixture corpus size (smoke set now, growth policy later) is an
  implementation detail deferred to the parity task.

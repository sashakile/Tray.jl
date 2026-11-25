# Change: Add Lean Assurance Twin with Parity Oracle

## Why
Tray's kernel correctness claims — `combine`/`identity` forming a monoid per
schema, range queries equal to naive left-to-right recomputation, and
incremental updates preserving the canonical fold — are currently verified only
empirically: Supposition properties sample bounded inputs, and the incremental
path compares against a canonical `combine` oracle *at runtime*. These are the
claims the falsifiable value proposition (5× faster range queries versus naive
O(n) recomputation) silently rests on: if query-equivalence ever broke, the
benchmarks would measure the wrong thing.

A sibling project (catherine) demonstrated a working Lean 4 **assurance-twin
architecture** on the same machine: a stdlib-only Lean re-implementation of the
kernel semantics, proved theorems about that twin, a parity oracle
cross-examining twin and implementation over a fixture corpus, and a
machine-checkable axiom audit. The pattern is verifier-language-agnostic (it
needs only JSON fixtures and exit codes), and Kani/Verus have no Julia
equivalent. The Lean toolchain (elan, Lean 4.36) is already provisioned here.

## What Changes
- Add a `lean/` Lake package (pinned toolchain, **standard-library only — no
  Mathlib**) defining a twin of the Tray kernel semantics: ordered leaves, a
  monoid payload interface, tree fold, inclusive range query, and persistent
  leaf replacement.
- Add proof modules proving, over any payload instance satisfying its monoid
  laws passed as explicit theorem hypotheses (never as axioms):
  - the monoid laws for the shipped token and additive instances (tasks 3.1);
  - range-query equivalence with naive left-to-right `foldl combine identity`
    recomputation (tasks 3.2);
  - incremental-maintenance equivalence — the replaced tree's cached aggregates
    equal the canonical fold of the new leaf vector (tasks 3.3).
- Add a `tray-parity` oracle executable that enumerates a committed
  integer-encoded JSON fixture corpus (natural-number and token-list payloads
  only), runs both the Julia implementation (via a small Julia emitter script)
  and the Lean twin over each fixture, and compares results with strict
  exit-code discipline: 0 = agreement, 1 = semantic divergence, 2 = harness
  failure that never masquerades as divergence.
- Add `scripts/check-lean-axioms.sh` — the `sorry`-free, assumption-free audit:
  `#print axioms` for every public theorem against the allowlist
  `{propext, Classical.choice, Quot.sound}`, failing on `sorryAx`, user-declared
  `axiom`, any `sorry` build warning, and any unexpected output.
- Add a `just lean` recipe (build twin → run parity → audit axioms) wired
  **outside `just ci`**: `ci` remains runnable on any checkout with only the
  Julia toolchain, while `lean` requires elan with the committed
  `lean/lean-toolchain` pin.
- Document provisioning, scope, and the twin's relationship to Supposition
  properties (PBT finds bugs on sampled inputs; Lean proves absence for the
  modeled semantics; parity keeps the twin honest against the implementation).

## Impact
- **New capability**: `lean-assurance-twin`.
- **Affected code**: New `lean/` tree, `scripts/` audit script, `justfile`
  recipe, and fixture-emitter script only. No production Julia source, no
  production dependency, no behavior change to Tray's public API or results.
- **Affected tests**: Existing suite unchanged; the parity corpus is committed
  fixture data, not `Pkg.test()` content.
- **Affected documentation**: Contributor docs gain a Lean-lane section
  (provisioning, scope boundary, proof-audit rules).

## Dependencies
- The property-based-testing change (complete) supplies the noncommutative
  token-payload conventions and independent-oracle discipline the twin proofs
  mirror.
- Implementation is gated on approval of this proposal; each proof target is
  filed as a beads issue shaped as a red→green cycle (`sorry` theorem = red,
  landed proof = green).
- Concurrent snapshot publication semantics (`TRAYS-ol9`) are explicitly out of
  scope; the twin models single-threaded persistent replacement only.

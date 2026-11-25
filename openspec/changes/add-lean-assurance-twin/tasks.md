## 1. Scaffold and provisioning lane
- [ ] 1.1 Create the `lean/` Lake package with committed `lean/lean-toolchain` pin (Lean 4.36), a `Tray` library root, and a `tray-parity` executable stub whose root module stays separate from kernel modules.
- [ ] 1.2 Add the `just lean` recipe (build → parity → audit) and verify it is not a `just ci` dependency by running `just ci` on a checkout path that never invokes lake.
- [ ] 1.3 Add `scripts/check-lean-axioms.sh` with its self-test (`--file` override) and allowlist parsing, red against a scratch file containing `sorry` and a user `axiom`, green on an empty twin.
- [ ] 1.4 File one beads issue per proof target (tasks 3.1–3.3) with the red→green shape so each ticket precedes its implementation cycle.

## 2. Kernel twin definitions
- [ ] 2.1 Define the payload interface as a structure (`combine`, `identity`) plus the token (noncommutative) and additive instances, test-driving each definition against expected reductions before proving.
- [ ] 2.2 Define ordered leaves, whole-tree fold, inclusive range query over `lo ≤ hi`, and persistent single-leaf replacement on plain leaf lists and a balanced-shape tree model, keeping every definition total and `simp`-normal.
- [ ] 2.3 Add the committed JSON fixture schema and corpus directory `lean/fixtures/` with an initial smoke set (small/odd sizes, `lo = hi`, full range, replacement at both ends). The schema SHALL pin: integer-encoded payloads only (natural-number and token-list; no floats), magnitude-bounded values that cannot wrap Julia's `Int64`, production-legal inputs only (nonempty trees, `1 ≤ lo ≤ hi ≤ n`), and default full-depth queries (`target_depth = nothing`).

## 3. Proofs (each item: state with `sorry` → audit red → land proof → audit green)
- [ ] 3.1 Prove associativity and identity for the token and additive payload instances.
- [ ] 3.2 Prove range-query equivalence: for any payload whose laws are hypotheses, `rangeQuery leaves lo hi = foldl combine identity leaves[lo..hi]`.
- [ ] 3.3 Prove incremental-maintenance equivalence: the replaced tree's cached fold equals the canonical fold of the new leaf vector, for any payload with proved laws.
- [ ] 3.4 Complete `Axioms.lean` with one `#print axioms` line per public theorem and verify the audit accepts only the classical allowlist.

## 4. Parity oracle and Julia emitter
- [ ] 4.1 Add `scripts/emit-parity-fixtures.jl` producing fixture JSON from the Julia implementation (root, range, post-replacement results), re-runnable to refresh the corpus mechanically.
- [ ] 4.2 Implement `tray-parity` corpus enumeration, JSON parsing, and comparison with exit codes 0/1/2 and distinct harness-vs-divergence reporting; test all three exits (agree, seeded divergence, corrupt fixture) before wiring into `just lean`.
- [ ] 4.3 Wire parity and audit into `just lean` and confirm end-to-end red/green behavior: pass on the landed twin, exit 1 on a deliberately perturbed twin result, exit 2 on a corrupt fixture.

## 5. Documentation and validation
- [ ] 5.1 Document the Lean lane for contributors: elan provisioning, pinned toolchain, what the twin proves, PBT/proof relationship, kernel scope boundary, and the drift workflow when `tray-parity` reports divergence.
- [ ] 5.2 Close each proof-target beads issue (filed in task 1.4) as its proof lands; record the catherine-pattern provenance in `wai`.
- [ ] 5.3 Run `openspec validate add-lean-assurance-twin --strict`, `just ci` (unchanged-green), `just lean` (green), `git diff --check`, and JuliaFormatter on any touched Julia files.

## 1. Clarify normative contracts
- [ ] 1.1 Amend the active attribution specification and design to identify allocation conventions as provenance for finalized leaf buckets.
- [ ] 1.2 Amend the active tree contract to state that leaves are already constructed schema-valid payloads.
- [ ] 1.3 Document source-partition semantics and the procedure for recomputing allocation at a different partition.

## 2. Test-drive reconciliation boundaries
- [ ] 2.1 Add tests proving residual correction occurs during external leaf construction.
- [ ] 2.2 Add adversarial floating-point/grouping tests proving internal combine never reapplies residual correction.
- [ ] 2.3 Add a test proving out-of-tolerance internal reconciliation invokes the REQ-3 rebuild/error policy.

## 3. Separate construction paths
- [ ] 3.1 Introduce an encapsulated non-correcting path for already-validated internally combined attribution values.
- [ ] 3.2 Keep public leaf construction validation, finiteness checks, and configured residual assignment unchanged.
- [ ] 3.3 Update attribution documentation to distinguish provenance from executable allocation.

## 4. Validate
- [ ] 4.1 Run focused attribution and tree tests plus the complete package test suite.
- [ ] 4.2 Run the required Rule of 5 review and fix findings.
- [ ] 4.3 Run `ah check --changes clarify-attribution-construction-boundary`, `openspec validate clarify-attribution-construction-boundary --strict`, and `git diff --check`.

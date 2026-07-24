## 1. Clarify normative contracts
- [x] 1.1 Amend the active attribution specification and design to identify allocation conventions as provenance for finalized leaf buckets.
- [x] 1.2 Amend the active tree contract to state that leaves are already constructed schema-valid payloads.
- [x] 1.3 Add immutable non-empty `source_partition_id` provenance to `Allocated`; document migration and recomputation at a different partition.

## 2. Test-drive reconciliation semantics
- [x] 2.1 Add tests proving inexact schemas require a residual and construction derives it from `realized_total` and non-residual buckets in schema order.
- [x] 2.2 Add adversarial grouping tests proving combine adds only independent coordinates and canonically rederives, rather than sums, the residual.
- [x] 2.3 Add tests for exact no-residual equality, non-finite/overflow rejection, identity, closure over representable fixtures, and deterministic full-tree recomputation.

## 3. Implement canonical reconciliation
- [x] 3.1 Add one schema-order residual derivation function shared by external construction and internal combination.
- [x] 3.2 Preserve and add `realized_total` and non-residual buckets; never treat the residual as an independently additive input coordinate.
- [x] 3.3 Update attribution documentation to distinguish provenance from executable allocation.

## 4. Validate
- [ ] 4.1 Create Espectacular contracts for the new scenarios, then run focused attribution and tree tests plus the complete package test suite.
- [ ] 4.2 Run the required Rule of 5 implementation review and fix findings.
- [ ] 4.3 Run `ah check --changes clarify-attribution-construction-boundary`, `openspec validate clarify-attribution-construction-boundary --strict`, and `git diff --check`.

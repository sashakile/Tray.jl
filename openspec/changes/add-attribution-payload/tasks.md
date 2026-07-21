## 1. Payload struct and algebra
- [x] 1.1 Implement `AttributionPayload{K}` with finite bucket vector, finite `realized_total`, and immutable ordered unique bucket IDs.
- [x] 1.2 Implement `combine` using elementwise bucket addition plus realized-total addition.
- [x] 1.3 Implement schema-aware `identity` producing zero buckets and zero total.
- [x] 1.4 Add alignment checks: mismatched length or non-identical bucket-identifier sequences raise an alignment error.

## 2. Reconciliation invariant
- [x] 2.1 Implement bucket-sum reconciliation at construction and schema-designated residual-gap assignment.
- [x] 2.2 Reject construction when buckets do not reconcile and the schema has no residual bucket.

## 3. Attribution convention
- [x] 3.1 Add schema configuration for `Direct` or `Allocated(method, ordered_factor_ids)` attribution.
- [x] 3.2 Support sequential allocation with factor order and symmetric allocation.
- [x] 3.3 Reject construction without a declared attribution convention.

## 4. Ratio-safe derived metrics
- [x] 4.1 Implement read-time derivation of ratio metrics (e.g., margin percentage) from additive numerator and denominator fields.
- [x] 4.2 Return a domain error when the denominator component is zero at the queried node.

## 5. Tests
- [x] 5.1 Unit tests for payload `combine`/`identity`, alignment errors, and reconciliation.
- [x] 5.2 Property tests for elementwise summation through multi-level tree grouping.
- [x] 5.3 Tests for direct and allocated convention configuration and provenance.
- [x] 5.4 Tests for read-time ratio derivation and zero-denominator domain errors.
- [ ] 5.5 Run `ah check --changes add-attribution-payload` and `openspec validate add-attribution-payload --strict`.

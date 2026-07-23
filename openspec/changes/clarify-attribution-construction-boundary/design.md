## Context
Tray's tree folds payloads, not arbitrary raw source records. For attribution, an upstream producer computes a reconciled bucket vector and constructs an `AttributionPayload`. The schema's `Allocated(method, ordered_factor_ids)` value records that producer decision; it is not an executable aggregate allocation function.

This boundary permits nonlinear allocation methods, but their semantics are tied to the producer's chosen partition. Tray guarantees additive aggregation of the supplied contributions, not equivalence to rerunning a nonlinear method over aggregated driver signals.

Separately, residual correction is appropriate when accepting an externally produced leaf payload. It is not a lawful merge operation: applying a tolerance-triggered correction at internal nodes can depend on grouping and obscure numerical drift that REQ-3 already governs.

## Goals / Non-Goals
- Goals:
  - Make the source-to-payload boundary unambiguous.
  - Prevent aggregate recomputation expectations for allocation provenance.
  - Preserve additive, grouping-independent attribution combination.
- Non-Goals:
  - Implement allocation algorithms or driver-signal storage in Tray.
  - Require every external allocation method to be linear.
  - Define a generic leaf-embedding API for all payload types.

## Decisions

### Allocation is finalized before payload construction
The producer supplies final additive buckets. `Allocated` records method and factor order only. If users require allocation over a different partition or query cut, they must recompute from source outside the aggregation tree and construct a new dataset revision.

### Residual correction is leaf-construction-only
The public leaf constructor may assign a gap to the configured residual bucket. Internal combine uses a validated non-correcting construction path after elementwise addition. Drift outside tolerance triggers deterministic rebuild or explicit error under REQ-3.

### Tree leaves are payloads
The generic tree contract starts at schema-valid `T` values. Domain adapters may provide constructors from raw records, but those constructors are not part of `combine`/`identity` and must document their own partition semantics.

## Risks / Trade-offs
- Existing callers that inferred aggregate allocation semantics must move that computation upstream.
- A non-correcting internal constructor requires careful encapsulation so callers cannot bypass leaf validation.
- Floating-point drift may now surface as a rebuild/error instead of being silently absorbed into a residual bucket.

## Migration Plan
Clarify specs and documentation first, add grouping-sensitive regression tests, then separate leaf validation/correction from internal payload construction without changing the public validated constructor.

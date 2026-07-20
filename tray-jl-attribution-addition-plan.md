# Tray.jl Attribution Payload Specification Plan

## Goal

Add a domain-neutral bucketed-attribution payload to Tray. Named buckets and a
realized total aggregate through the existing ordered-array and balanced-index
contracts. Example applications include telemetry-source contribution,
forecast-vs-actual bridges, cohort contribution, operational waterfalls, and
optional financial P&L attribution.

## Specification artifacts

The active OpenSpec change is
[`add-attribution-payload`](openspec/changes/add-attribution-payload/):

- `proposal.md` defines scope and impact.
- `design.md` records payload ownership, reconciliation, attribution-convention,
  and ratio-safety decisions.
- `specs/attribution-payload/spec.md` owns REQ-45–REQ-48.
- `tasks.md` defines the future implementation and verification work.

The authoritative combined source is
[`tray-jl-ears-spec.md`](tray-jl-ears-spec.md). Its Addendum B contains
REQ-45–REQ-48. Documentation mirrors that root source and the complete
`openspec/` tree automatically; generated documentation is never edited by
hand.

## Decisions

1. `AttributionPayload{K}` stores finite named buckets and a finite
   `realized_total`; combination adds both, and schema identity zeros both.
2. Every payload reconciles its bucket sum with its realized total under the
   configured numerical tolerance. A schema-designated residual bucket may
   absorb a gap; otherwise construction fails.
3. Every schema records either `Direct` attribution or
   `Allocated(method, ordered_factor_ids)`. Sequential and symmetric allocation
   are supported without a hidden default.
4. Ratios remain derived read-time values over additive components and fail for
   a zero denominator.
5. Attribution uses generic Tray operations and does not depend on sample
   compression or the optional financial-risk adapter.

## Verification before implementation

- `openspec validate add-attribution-payload --strict`
- Confirm REQ-45–REQ-48 occur exactly once in the OpenSpec capability and once
  in the authoritative EARS source.
- Build documentation and compare its generated mirrors byte-for-byte with
  `openspec/` and `tray-jl-ears-spec.md`.
- Run `ah check --changes add-attribution-payload`; `no-toml` findings remain
  expected until implementation contracts are added.

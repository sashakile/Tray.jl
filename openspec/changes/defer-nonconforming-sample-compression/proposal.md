# Change: Defer non-conforming sample compression

## Why
REQ-21 requires compressed sample aggregation to approximate the distribution of the elementwise sum of aligned sample vectors. ADR-002's Greenwald-Khanna union and the current fixed-bin histogram union instead summarize concatenated marginal distributions, which discard pairing and cannot distinguish inputs whose paired sums differ.

Keeping those implementations under the REQ-21 name would silently return statistics for the wrong population. Exact sample vectors are already lawful, so the smallest safe correction is to retain exact operation and defer compression until a pairing-preserving representation is approved.

## What Changes
- Make exact aligned sample vectors the only conforming sample-node representation for the current release.
- Mark ADR-002's GK merge decision as superseded and prohibit presenting marginal histogram/GK union as aligned-sum compression.
- Remove or clearly quarantine the current `HistogramSketch` and `CompressedSamplePayload` public claims as experimental pooled-distribution behavior rather than REQ-21 behavior.
- Require exact sample combination to recompute all summary fields from the elementwise-summed vector.
- Define an adversarial aligned-sum oracle that any future compressed representation must pass before REQ-21 compression is re-enabled.
- Defer mixed exact/compressed promotion laws until a viable pairing-preserving representation is proposed.

## Impact
- Affected specs: `sample-analytics`
- Affected active change: `add-tray-capabilities` (REQ-21, REQ-22, REQ-32, REQ-44 and task 3.3)
- Affected architecture: `openspec/adr/ADR-002-sketch-interface.md`
- Affected code: `src/sample_analytics.jl`, `src/Tray.jl`, sample analytics tests and documentation
- **BREAKING**: APIs currently described as conforming compressed sample analytics may be removed from the public surface or explicitly moved to an experimental non-REQ-21 namespace.

# Change: Defer non-conforming sample compression

## Why
REQ-21 requires compressed sample aggregation to approximate the distribution of the elementwise sum of aligned sample vectors. ADR-002's Greenwald-Khanna union and the current fixed-bin histogram union instead summarize concatenated marginal distributions, which discard pairing and cannot distinguish inputs whose paired sums differ.

Keeping those implementations under the REQ-21 name would silently return statistics for the wrong population. Exact vector addition provides a viable path once its cached-summary defect is corrected, so the smallest safe change is to retain corrected exact operation and defer compression until a pairing-preserving representation is approved.

## What Changes
- Make exact aligned sample vectors the only conforming sample-node representation for the current release.
- Mark ADR-002's GK merge decision as superseded and prohibit presenting marginal histogram/GK union as aligned-sum compression.
- Remove `HistogramSketch` and `CompressedSamplePayload` from the public API and REQ-21 documentation; any future pooled-distribution capability requires a separate proposal and namespace.
- Require exact sample construction, identity, and combination to derive coherent summary fields from their aligned vectors.
- Define an adversarial aligned-sum oracle that any future compressed representation must pass before REQ-21 compression is re-enabled.
- Defer mixed exact/compressed promotion laws until a viable pairing-preserving representation is proposed.

## Impact
- Affected specs: `sample-analytics`
- Affected active change: `add-tray-capabilities` (REQ-21, REQ-22, REQ-32, REQ-44 and task 3.3)
- Affected architecture: `openspec/adr/ADR-002-sketch-interface.md`
- Affected code: `src/sample_analytics.jl`, `src/Tray.jl`, sample analytics tests and documentation
- **BREAKING**: `HistogramSketch`, `CompressedSamplePayload`, and compressed-query APIs currently described as REQ-21 conforming are removed from the public surface.

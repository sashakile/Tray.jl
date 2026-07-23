## 1. Correct the specification and architecture record
- [ ] 1.1 Mark ADR-002 superseded with the paired-sum indistinguishability counterexample.
- [ ] 1.2 Amend the active `add-tray-capabilities` REQ-21, design, and task 3.3 to make exact vectors the only currently conforming representation.
- [ ] 1.3 Document the acceptance gate for any future pairing-preserving compression proposal.

## 2. Test-drive exact sample correctness
- [ ] 2.1 Add a regression proving exact combine uses elementwise-sum statistics rather than concatenated child statistics.
- [ ] 2.2 Add adversarial re-pairing fixtures whose inputs have equal marginal histograms but different elementwise-sum quantiles.
- [ ] 2.3 Add exact identity, associativity, and full-tree recomputation checks using independent vector oracles.

## 3. Restore a truthful public surface
- [ ] 3.1 Recompute exact scalar summary fields from each elementwise-combined vector.
- [ ] 3.2 Make requests for conforming compression fail explicitly until a replacement is approved.
- [ ] 3.3 Remove or quarantine `HistogramSketch` and `CompressedSamplePayload` claims, exports, tests, and documentation that identify marginal union as REQ-21 aligned-sum behavior.

## 4. Validate
- [ ] 4.1 Run focused sample analytics tests and the complete package test suite.
- [ ] 4.2 Run the required Rule of 5 review and fix findings.
- [ ] 4.3 Run `ah check --changes defer-nonconforming-sample-compression`, `openspec validate defer-nonconforming-sample-compression --strict`, and `git diff --check`.

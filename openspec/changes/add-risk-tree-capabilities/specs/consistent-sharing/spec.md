## ADDED Requirements

### Requirement: REQ-23 Atomic read visibility
Every point/range/subtree mutation, insertion/removal/rebalance, lazy flush, regeneration, rebuild, cache update, configuration or representation transition, and persistent publication SHALL execute in one transaction that atomically publishes a complete immutable snapshot epoch. Every root, range, multidimensional, and other multi-node read SHALL pin one epoch for its duration. Different-leaf writers sharing ancestors SHALL serialize or retry against the published epoch so neither update is lost. Any validation, allocation, I/O, or computation failure SHALL discard staged nodes, topology, caches, and metadata and preserve the prior snapshot.

#### Scenario: Read during ancestor propagation
- **WHEN** a root read overlaps a leaf update
- **THEN** the returned root payload equals a valid full-tree aggregate from before or after the update

#### Scenario: Concurrent writers share ancestors
- **WHEN** two writers update different leaves whose paths share an ancestor
- **THEN** both commits appear in one serial order, the final root contains both updates, and no reader observes mixed nodes

#### Scenario: Roll back a failed rebuild
- **WHEN** rebuilding nodes or caches fails before publication
- **THEN** topology, payloads, caches, configuration, and published epoch remain exactly at the prior snapshot

### Requirement: REQ-24 Shared-memory reads without full deserialization
While live shared-memory mode is active, compatible readers SHALL query directly from mapped node/header regions without allocating or decoding a private whole-tree object. Compatibility SHALL require a common conformance fixture. Observability SHALL expose deterministic counters for bytes mapped/touched, nodes decoded, node visits, combinations, canonical nodes emitted, retries, and full-deserialization attempts; counter increments SHALL be specified per operation and tests SHALL require zero full-deserialization attempts and complexity bounds after subtracting emitted-node work.

#### Scenario: Attach a second process
- **WHEN** either a second Julia process or a non-Julia process declared compatible with the active format version opens an existing shared tree
- **THEN** that process passes the format conformance fixture and queries node data directly from the shared representation without reconstructing the entire tree

### Requirement: REQ-26 Optional memory-mapped persistence
Where persistence is enabled, the versioned mapped format SHALL identify magic, format version, byte order, numeric types, dimensions, schema/configuration provenance, offsets, checksums, and committed snapshot epoch. Readers SHALL support a documented version range and reject unsupported versions. Upgrades SHALL copy the committed source to a separate target, transform it without modifying source, validate checksums/invariants/conformance fixture and semantic root/range samples, then atomically switch the active pointer; any interruption or failure SHALL leave or restore the source as active, and old files SHALL remain readable until explicit cleanup after cutover.

#### Scenario: Read from a non-Julia process
- **WHEN** a foreign-language reference reader maps the conformance fixture for a declared-compatible format version
- **THEN** it validates the header and reads the expected snapshot without receiving a full serialized copy from the Julia process

#### Scenario: Reject an incompatible mapping
- **WHEN** a reader encounters unknown magic bytes, unsupported format version, incompatible element representation, or incomplete snapshot epoch
- **THEN** it rejects the mapping without exposing partial tree data

#### Scenario: Upgrade with rollback
- **WHEN** a persistent format upgrade succeeds or fails at any step
- **THEN** readers see exactly one validated old or new committed format, and failure leaves the old mapping active and unchanged

### Requirement: REQ-35 Same-leaf writer serialization
If concurrent shared-memory writers update the same leaf, the library SHALL serialize the updates, using internal retry where needed, so both valid updates complete in one observable order and neither is lost.

#### Scenario: Two writers update one leaf
- **WHEN** two writers concurrently submit valid updates to the same leaf
- **THEN** both operations complete and their acknowledgements and final leaf value match one serial application order

### Requirement: REQ-40 Consistent range read during reweighting
If a range query overlaps any concurrent mutation, including subtree reweighting, the query SHALL use one complete pre-mutation or post-mutation snapshot epoch across the entire range.

#### Scenario: Query spans a changing subtree
- **WHEN** a range query spans both a subtree being reweighted and an unaffected subtree
- **THEN** all canonical nodes contributing to the result come from one consistent tree version

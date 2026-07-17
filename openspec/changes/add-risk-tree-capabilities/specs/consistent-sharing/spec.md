## ADDED Requirements

### Requirement: REQ-23 Atomic read visibility
While root reads occur concurrently with a leaf update, each reader SHALL observe either the pre-update or post-update root payload and SHALL NOT observe a partially propagated root payload.

#### Scenario: Read during ancestor propagation
- **WHEN** a root read overlaps a leaf update
- **THEN** the returned root payload equals a valid full-tree aggregate from before or after the update

### Requirement: REQ-24 Shared-memory reads without full deserialization
While live shared-memory mode is active, multiple Julia processes and every non-Julia reader declared compatible with the active binary-format version SHALL read tree data directly from the mapping without fully deserializing the structure into a private copy. Compatibility SHALL require passing a common conformance fixture.

#### Scenario: Attach a second process
- **WHEN** either a second Julia process or a non-Julia process declared compatible with the active format version opens an existing shared tree
- **THEN** that process passes the format conformance fixture and queries node data directly from the shared representation without reconstructing the entire tree

### Requirement: REQ-26 Optional memory-mapped persistence
Where cross-process persistence is enabled, the library SHALL expose a memory-mapped, structurally shared persistent representation whose header identifies magic bytes, format version, byte order, numeric element types, dimensions, node-table offsets, and snapshot epoch. Every reader declared compatible with that version SHALL read it without retransmitting or fully deserializing the tree.

#### Scenario: Read from a non-Julia process
- **WHEN** a foreign-language reference reader maps the conformance fixture for a declared-compatible format version
- **THEN** it validates the header and reads the expected snapshot without receiving a full serialized copy from the Julia process

#### Scenario: Reject an incompatible mapping
- **WHEN** a reader encounters unknown magic bytes, unsupported format version, incompatible element representation, or incomplete snapshot epoch
- **THEN** it rejects the mapping without exposing partial tree data

### Requirement: REQ-35 Same-leaf writer serialization
If concurrent shared-memory writers update the same leaf, the library SHALL serialize the updates, using internal retry where needed, so both valid updates complete in one observable order and neither is lost.

#### Scenario: Two writers update one leaf
- **WHEN** two writers concurrently submit valid updates to the same leaf
- **THEN** both operations complete and their acknowledgements and final leaf value match one serial application order

### Requirement: REQ-40 Consistent range read during reweighting
If a range query overlaps a concurrent subtree reweighting, the query SHALL use one complete pre-reweight or post-reweight version across the entire range.

#### Scenario: Query spans a changing subtree
- **WHEN** a range query spans both a subtree being reweighted and an unaffected subtree
- **THEN** all canonical nodes contributing to the result come from one consistent tree version

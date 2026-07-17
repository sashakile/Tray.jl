## ADDED Requirements

### Requirement: REQ-23 Atomic read visibility
While root reads occur concurrently with a leaf update, each reader SHALL observe either the pre-update or post-update root payload and SHALL NOT observe a partially propagated root payload.

#### Scenario: Read during ancestor propagation
- **WHEN** a root read overlaps a leaf update
- **THEN** the returned root payload equals a valid full-tree aggregate from before or after the update

### Requirement: REQ-24 Shared-memory reads without full deserialization
While shared-memory mode is active, multiple Julia processes and a Julia process sharing with a supported non-Julia process SHALL read tree data without fully deserializing the shared structure into a private copy.

#### Scenario: Attach a second process
- **WHEN** either a second Julia process or a supported non-Julia process opens an existing shared tree
- **THEN** that process can query node data directly from the shared representation without reconstructing the entire tree

### Requirement: REQ-26 Optional memory-mapped persistence
Where cross-process persistence is enabled, the library SHALL expose a memory-mapped, structurally shared persistent representation readable by supported non-owning processes without retransmitting or fully deserializing the tree.

#### Scenario: Read from a non-Julia process
- **WHEN** a supported foreign-language process maps a persisted tree using the published layout
- **THEN** it can read a consistent tree version without receiving a full serialized copy from the Julia process

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

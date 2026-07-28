## ADDED Requirements

### Requirement: REQ-49 Tree contract scenarios
#### Scenario: Range query computes same as fold
- **WHEN** a range query [lo, hi] is performed on a tree
- **THEN** the result equals the fold of combine across all leaves in that range

#### Scenario: Insert preserves existing values
- **WHEN** a leaf is inserted at a valid position
- **THEN** all other leaf values remain unchanged

#### Scenario: Remove preserves ordering
- **WHEN** a leaf is removed from a non-trivial tree
- **THEN** the relative ordering of remaining leaves is preserved

### Requirement: REQ-50 ScalarSummary contract scenarios
#### Scenario: Combine is associative and commutative
- **WHEN** ScalarSummary instances are combined in any order
- **THEN** the result is the same regardless of grouping or ordering

#### Scenario: Identity law
- **WHEN** identity is combined with any ScalarSummary
- **THEN** the result equals the original ScalarSummary

### Requirement: REQ-51 SamplePayload contract scenarios
#### Scenario: Combine uses elementwise sum statistics
- **WHEN** SamplePayload instances are combined
- **THEN** the resulting statistics are the elementwise sum of the individual statistics

#### Scenario: Regenerate increments revision
- **WHEN** samples are regenerated
- **THEN** the revision counter is incremented

### Requirement: REQ-52 SnapshotEpoch contract scenarios
#### Scenario: Insert produces new revision
- **WHEN** a leaf is inserted into a SnapshotEpoch-wrapped tree
- **THEN** a new revision is created

#### Scenario: Publish atomically exchanges snapshot
- **WHEN** publish! is called
- **THEN** the active snapshot is atomically exchanged

### Requirement: REQ-53 DashboardModel contract scenarios
#### Scenario: Latest request wins
- **WHEN** multiple query requests arrive before the first completes
- **THEN** only the latest request's result is published

#### Scenario: Subscribe receives notifications
- **WHEN** a field changes on the DashboardModel
- **THEN** all subscribers are notified
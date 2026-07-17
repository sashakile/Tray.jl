## ADDED Requirements

### Requirement: REQ-8 Separate hierarchy instances
The library SHALL represent independent groupby and time hierarchies as separate `RiskTree` instances sharing the same leaf-level scenario matrix and SHALL NOT require a materialized hierarchy cross-product.

#### Scenario: Register book and time hierarchies
- **WHEN** callers organize the same leaves by book and by time
- **THEN** each organization has its own tree and both reference the same aligned leaf scenario source

### Requirement: REQ-25 Independent axis updates
While multiple groupby axes share one leaf scenario matrix, each axis tree SHALL be independently updatable without rebuilding the other axis trees.

#### Scenario: Change one hierarchy
- **WHEN** a hierarchy or aggregate on one registered axis is updated without changing shared leaf scenarios
- **THEN** that axis reflects the update and other axis trees retain their prior structures and payload versions

### Requirement: REQ-39 Composed multidimensional slices
While multiple groupby axes and a time axis share a leaf scenario matrix, an intersection query SHALL compose the independent canonical range decompositions for the requested cuts and SHALL NOT materialize a full cross-product cube.

#### Scenario: Query a desk over a time range
- **WHEN** at least two groupby axes and a time axis are registered and a caller intersects one groupby cut with one time range
- **THEN** the result includes exactly leaves belonging to both cuts, uses both independent decompositions, and creates no cross-product structure

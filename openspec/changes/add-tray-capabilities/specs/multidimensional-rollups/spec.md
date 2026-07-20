## ADDED Requirements

### Requirement: REQ-8 Separate hierarchy instances
The library SHALL represent independent categorical and ordered hierarchies as separate Tray indices over the same immutable leaf IDs and dataset revision and SHALL NOT require a materialized hierarchy cross-product. Each axis SHALL maintain a revisioned map from every axis node/cut to a set of leaf IDs and a reverse leaf-ID membership map.

#### Scenario: Register category and time hierarchies
- **WHEN** callers organize the same leaves by category and by time
- **THEN** each organization has its own index and both reference the same leaf source revision

### Requirement: REQ-25 Independent axis updates
While multiple axes share one leaf source, each aggregation index SHALL be independently updatable without rebuilding the other indices.

#### Scenario: Change one hierarchy
- **WHEN** a hierarchy or aggregate on one registered axis is updated without changing shared leaves
- **THEN** that axis reflects the update and other indices retain their prior structures and payload revisions

### Requirement: REQ-39 Composed multidimensional slices
While multiple axes share a source, an intersection query SHALL snapshot all requested axis maps and the aggregation index at one dataset revision, reject any cross-version combination, obtain each cut's leaf-ID set, compute their exact set intersection, sort resulting IDs by current array order, coalesce consecutive indices into maximal ranges, canonically decompose each range, and fold nodes left-to-right in range/index order. It SHALL visit no leaf outside the intersection and SHALL NOT materialize a cross-product cube.

#### Scenario: Query a category over a time range
- **WHEN** categorical and time axes are registered and a caller intersects one category cut with one time range
- **THEN** the result includes exactly leaves belonging to both cuts, uses both independent decompositions, and creates no cross-product structure

#### Scenario: Reject cross-version axes
- **WHEN** requested axis snapshots or the aggregation index carry different dataset revisions
- **THEN** the query fails with a version-alignment error and returns no partial aggregate

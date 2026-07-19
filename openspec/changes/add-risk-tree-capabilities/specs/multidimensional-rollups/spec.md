## ADDED Requirements

### Requirement: REQ-8 Separate hierarchy instances
The library SHALL represent independent groupby and time hierarchies as separate `RiskTree` instances over the same immutable leaf IDs and source epoch and SHALL NOT require a materialized hierarchy cross-product. Each axis SHALL maintain a versioned map from every axis node/cut to a set of leaf IDs and a reverse leaf-ID membership map.

#### Scenario: Register book and time hierarchies
- **WHEN** callers organize the same leaves by book and by time
- **THEN** each organization has its own tree and both reference the same aligned leaf scenario source

### Requirement: REQ-25 Independent axis updates
While multiple groupby axes share one leaf scenario matrix, each axis tree SHALL be independently updatable without rebuilding the other axis trees.

#### Scenario: Change one hierarchy
- **WHEN** a hierarchy or aggregate on one registered axis is updated without changing shared leaf scenarios
- **THEN** that axis reflects the update and other axis trees retain their prior structures and payload versions

### Requirement: REQ-39 Composed multidimensional slices
While multiple axes share a source, an intersection query SHALL snapshot all requested axis maps and the tree at one source/scenario epoch, reject any cross-version combination, obtain each cut's leaf-ID set, compute their exact set intersection, sort resulting IDs by the tree's current deterministic leaf order, coalesce consecutive indices into maximal ranges, canonically decompose each range, and fold nodes left-to-right in range/index order. It SHALL visit no leaf outside the intersection and SHALL NOT materialize a cross-product cube.

#### Scenario: Query a desk over a time range
- **WHEN** at least two groupby axes and a time axis are registered and a caller intersects one groupby cut with one time range
- **THEN** the result includes exactly leaves belonging to both cuts, uses both independent decompositions, and creates no cross-product structure

#### Scenario: Reject cross-version axes
- **WHEN** requested axis snapshots or the payload tree carry different source or scenario epochs
- **THEN** the query fails with a version-alignment error and returns no partial aggregate

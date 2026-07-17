## ADDED Requirements

### Requirement: REQ-27 Optional dashboard model protocol
Where browser-dashboard integration is enabled, the library SHALL expose a kernel-agnostic serializable model implementing `get(key)`, `set(key, value)`, and `on("change:<key>", callback)` for keys `viewport_range`, `requested_depth`, `aggregate`, and `effective_depth`. Changes to `viewport_range` or `requested_depth` SHALL trigger the corresponding range query and update both result keys without integration-specific adapters.

#### Scenario: Pan or zoom a dashboard
- **WHEN** the frontend sets valid `viewport_range` or `requested_depth` values
- **THEN** the backend executes the corresponding range query, sets `aggregate` and `effective_depth`, and emits their change notifications

#### Scenario: Reject an invalid dashboard query
- **WHEN** the frontend sets an out-of-bounds viewport or invalid depth
- **THEN** the model reports the same bounds or domain error as the query API and does not publish a new aggregate

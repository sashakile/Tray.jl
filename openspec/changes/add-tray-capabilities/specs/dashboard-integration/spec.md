## ADDED Requirements

### Requirement: REQ-27 Optional dashboard model protocol
Where dashboard integration is enabled, the library SHALL expose a transport-neutral serializable model implementing `get`, `set`, and change callbacks for `viewport_range`, `requested_depth`, `request_revision`, `aggregate`, `effective_depth`, `error`, and `result_revision`. Each input change SHALL atomically capture both inputs and assign a strictly increasing revision. Computations MAY overlap, but only the latest issued revision SHALL publish; it SHALL atomically publish `(aggregate, effective_depth, error, result_revision)`, with exactly one of aggregate or error populated. Superseded successes/errors SHALL be discarded without notifications.

#### Scenario: Pan or zoom a dashboard
- **WHEN** the frontend sets valid `viewport_range` or `requested_depth` values
- **THEN** the backend executes the corresponding range query, sets `aggregate` and `effective_depth`, and emits their change notifications

#### Scenario: Reject an invalid dashboard query
- **WHEN** the frontend sets an out-of-bounds viewport or invalid depth
- **THEN** the model reports the same bounds or domain error as the query API and does not publish a new aggregate

#### Scenario: Latest request wins
- **WHEN** an older slow request completes after a newer request
- **THEN** only the newer revision atomically publishes its result or error and subscribers never observe mismatched result fields

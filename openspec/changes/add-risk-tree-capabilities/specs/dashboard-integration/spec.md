## ADDED Requirements

### Requirement: REQ-27 Optional dashboard model protocol
Where browser-dashboard integration is enabled, the library SHALL expose current viewport aggregate and level of detail through a kernel-agnostic serializable model with getter, setter, and change-notification semantics, and a frontend viewport change SHALL be able to trigger a range query without integration-specific glue.

#### Scenario: Pan or zoom a dashboard
- **WHEN** the frontend updates viewport bounds or level of detail through the shared model
- **THEN** the backend executes the corresponding range query and publishes the resulting aggregate and effective level of detail through that model

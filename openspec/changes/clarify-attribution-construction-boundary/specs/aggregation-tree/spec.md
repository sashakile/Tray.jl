## ADDED Requirements

### Requirement: Constructed payload leaf boundary
The generic aggregation tree SHALL accept schema-valid payload values `T` as leaves. Conversion from domain source records into `T` is owned by payload constructors or upstream adapters and is not an implicit tree operation. Tree-level update and reweight operations SHALL act on payload values according to their declared contracts and SHALL NOT choose between pre- and post-conversion source semantics.

#### Scenario: Build from domain payloads
- **WHEN** an adapter converts source records into schema-valid payload values and supplies them as leaves
- **THEN** the tree validates and folds those payloads without invoking another source-to-payload conversion

#### Scenario: Reweight a payload subtree
- **WHEN** a payload type declares reweighting and a caller reweights a canonical subtree
- **THEN** the operation applies to the subtree's payload leaves under the declared payload action rather than to unavailable raw source records

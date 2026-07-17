## ADDED Requirements

### Requirement: REQ-1 Generic n-ary tree
The library SHALL represent aggregation as a non-empty n-ary tree parameterized by a payload type `T <: AbstractPayload` and integer branching factor `b ≥ 2`.

#### Scenario: Construct a typed tree
- **WHEN** a caller constructs a tree from payloads of a concrete `AbstractPayload` subtype and a branching factor
- **THEN** every node uses that payload type and each internal node can have up to the configured number of children

#### Scenario: Reject an invalid tree domain
- **WHEN** a caller supplies no leaves or a branching factor less than two
- **THEN** construction fails with a domain error before any nodes are built

### Requirement: REQ-2 Payload algebra contract
Every payload type used in a tree MUST provide closed operations `combine(::T, ::T)::T` and `identity(::Type{T})::T`. Associativity SHALL be documented as the payload implementer's responsibility and SHALL NOT be checked at runtime.

#### Scenario: Build with a conforming custom payload
- **WHEN** a custom payload provides both required methods returning `T`
- **THEN** the tree accepts that payload without attempting runtime associativity checks

#### Scenario: Reject a missing identity method
- **WHEN** a custom payload provides `combine` but not `identity(::Type{T})::T`
- **THEN** it cannot be used as a tree payload

### Requirement: REQ-3 Bottom-up construction
The library SHALL compute each internal node payload by folding `combine` over its child payloads from the leaves to the root.

#### Scenario: Build from leaves
- **WHEN** a tree is built from a non-empty sequence of leaf payloads
- **THEN** each internal payload equals the fold of its children and the root equals the fold of all leaves

### Requirement: REQ-9 Logarithmic update path
For fixed branching factor `b`, the library SHALL update a leaf through a root path whose length is `O(log_b n)`, where `n` is the leaf count.

#### Scenario: Update one leaf
- **WHEN** one leaf is replaced as leaf count grows at fixed branching factor
- **THEN** only that leaf and its ancestors are recomputed and the number of visited nodes grows as `O(log_b n)`

### Requirement: REQ-10 Canonical range decomposition
The library SHALL decompose an in-bounds, non-empty, closed 1-based leaf-index range `[lo, hi]` into the minimal set of canonical tree nodes used by standard segment-tree decomposition.

#### Scenario: Decompose a partial range
- **WHEN** a caller queries a range that does not coincide with one subtree
- **THEN** the returned decomposition exactly covers the range without overlap and contains no complete set of a parent's children replaceable by that parent

### Requirement: REQ-11 Ancestor recomputation after update
When a leaf payload is updated, the library SHALL recompute every ancestor payload through the root.

#### Scenario: Changed leaf affects root
- **WHEN** a caller updates a leaf payload
- **THEN** every ancestor reflects the replacement payload and nodes outside the ancestor path remain unchanged

#### Scenario: Reject an invalid update index
- **WHEN** a caller updates an index outside `1:n`
- **THEN** the update fails with a bounds error and leaves every node unchanged

### Requirement: REQ-12 Target-depth range query
Root depth SHALL be zero and each child depth SHALL be its parent depth plus one. When a caller invokes a range query at integer target depth `d` in `[0, h]`, where `h` is maximum leaf depth, the library SHALL use the minimal canonical nodes with depth at most `d` and return their payloads folded with `combine`. The requested range MUST be exactly representable by such nodes.

#### Scenario: Query at a requested detail level
- **WHEN** an in-bounds range and valid target depth are supplied
- **THEN** the result equals a direct fold of leaves in the range, no selected canonical node is below the target depth, and no smaller eligible canonical-node set covers the range

#### Scenario: Reject a depth-incompatible range
- **WHEN** a range boundary cuts through every canonical node available at or above target depth `d`
- **THEN** the query fails with a depth-alignment error rather than including leaves outside the range

#### Scenario: Reject an invalid integer depth
- **WHEN** target depth is less than zero or greater than maximum leaf depth
- **THEN** the query fails with a domain error

### Requirement: REQ-13 Read-only derived query
When a caller requests a statistic not stored natively by a payload, the library SHALL derive it from the queried merged payload without mutating the tree.

#### Scenario: Derive a statistic
- **WHEN** a caller requests a supported statistic absent from the merged payload's stored fields
- **THEN** the statistic is computed from that payload and a complete tree-state comparison shows no mutation

### Requirement: REQ-14 Leaf insertion
When a leaf is inserted, the library SHALL extend or rebalance the tree and update every affected ancestor payload.

#### Scenario: Insert a leaf
- **WHEN** a caller inserts a valid payload at a valid leaf position
- **THEN** the leaf count and ordering include it, the structure is extended or rebalanced as needed, and every affected internal node equals the fold of its current children

#### Scenario: Reject an invalid insertion position
- **WHEN** an insertion position is outside `1:(n + 1)`
- **THEN** insertion fails with a bounds error and leaves the tree unchanged

### Requirement: REQ-15 Leaf removal
When a leaf is removed, the library SHALL update every affected ancestor to exclude that leaf.

#### Scenario: Remove a leaf
- **WHEN** a caller removes an existing leaf
- **THEN** the leaf count decreases by one and every affected ancestor equals the fold of its remaining children

#### Scenario: Reject removal of the final leaf
- **WHEN** a caller attempts to remove the sole leaf
- **THEN** removal fails with a domain error and the non-empty tree remains unchanged

#### Scenario: Reject an invalid removal index
- **WHEN** a caller removes an index outside `1:n`
- **THEN** removal fails with a bounds error and leaves the tree unchanged

### Requirement: REQ-18 Localized subtree reweighting
When a caller supplies a payload-specific `reweight(::T, weight)::T` operation and reweights a subtree, the library SHALL apply it to that subtree's leaves and recompute only the subtree and its ancestor path rather than rebuilding the full tree.

#### Scenario: Reweight one subtree
- **WHEN** a defined payload-specific reweight operation is applied to a canonical subtree
- **THEN** a combination-call or node-version trace shows recomputation only within the transformed subtree and its ancestor path

#### Scenario: Reject an undefined reweight operation
- **WHEN** a payload type does not define reweighting for the supplied weight
- **THEN** the request fails before mutation with an informative contract error

### Requirement: REQ-19 Fractional-depth query
Except for scenario quantiles governed by `REQ-38`, when a caller requests finite fractional depth `d` in `[0, h]` for a numeric scalar or fixed-length numeric-vector payload with identical schemas at adjacent depths, the library SHALL obtain results for the same range at `floor(d)` and `ceil(d)`, linearly interpolate each field with weight `d - floor(d)`, and derive statistics only after interpolation.

#### Scenario: Interpolate between detail levels
- **WHEN** a range is valid at both adjacent depths, the payload is interpolatable, and `d` is not an integer
- **THEN** the statistic is derived from payload fields interpolated according to the fractional part of `d`

#### Scenario: Query an integer-valued fractional depth
- **WHEN** `d` is an integer in `[0, h]`
- **THEN** the result equals the ordinary target-depth result at `d` without interpolation

#### Scenario: Reject unsupported interpolation
- **WHEN** `d` is non-finite or outside `[0, h]`, adjacent schemas differ, or a payload field is not numeric
- **THEN** the query fails with an informative domain or interpolation error

### Requirement: REQ-29 Optional lazy range updates
Where lazy propagation is enabled, the library SHALL permit a range or subtree transformation `f` to be represented at a canonical subtree root only when it is declared distributive over payload combination, `f(combine(a, b)) = combine(f(a), f(b))`. The library SHALL defer descendant recomputation until a descendant is read.

#### Scenario: Defer a bulk update
- **WHEN** a bulk update fully covers a canonical subtree
- **THEN** the subtree aggregate reflects the update without eagerly visiting every leaf and a later descendant read resolves the deferred update correctly

#### Scenario: Reject a non-distributive lazy update
- **WHEN** a transformation is not declared distributive over `combine`
- **THEN** the library rejects lazy application rather than producing an invalid subtree aggregate

### Requirement: REQ-31 Missing payload operation error
If a payload type does not provide `combine(::T, ::T)::T`, use as a tree payload SHALL fail at compile time or construction time with an informative contract error and SHALL NOT select a default merge.

#### Scenario: Reject a non-conforming payload
- **WHEN** a caller attempts to use a payload without `combine(::T, ::T)::T`
- **THEN** compilation or construction fails before aggregation begins and identifies the missing operation

### Requirement: REQ-34 Query bounds enforcement
If any part of a query range lies outside the tree's leaf index, or if `lo > hi`, the library SHALL raise a bounds error rather than returning an empty, partial, or padded result.

#### Scenario: Reject an out-of-bounds range
- **WHEN** a range starts before the first leaf, ends after the last leaf, or has `lo > hi`
- **THEN** the query raises a bounds error and returns no aggregate

### Requirement: REQ-41 Point and decomposition complexity
For fixed branching factor `b`, point updates SHALL take `O(log_b n)` time. Finding the canonical decomposition of a range SHALL take `O(log_b n)` search time plus `O(k)` to visit or return its `k` canonical nodes.

#### Scenario: Scale a balanced tree
- **WHEN** leaf count grows while branching factor remains fixed
- **THEN** measured update path length and decomposition search work grow logarithmically apart from emitted-node work

### Requirement: REQ-42 Linear construction complexity
Full bottom-up construction from `n` leaves SHALL take `O(n)` time.

#### Scenario: Build a complete tree
- **WHEN** the number of input leaves is increased at fixed branching factor
- **THEN** instrumented total construction work, including node creation, structural operations, and combinations, grows linearly in the leaf count

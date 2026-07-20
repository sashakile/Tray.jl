# Aggregation Context

| Term | Definition |
|------|------------|
| **Leaf array** | Authoritative ordered storage for atomic values and stable IDs |
| **Aggregation index** | Balanced n-ary tree derived from the leaf array |
| **Node** | Vertex in the index holding a cached summary and child references |
| **Leaf** | Array record identified independently of its current rank |
| **Internal node** | Index node whose summary is computed from its children |
| **Root** | Top-most index node summarizing the entire array |
| **Branching factor** | `b` — maximum children per node |
| **Bottom-up** | Construction/update direction: children → parent → root |
| **Merge** | `combine(a, b) :: T` — associative, closed binary operation |
| **Canonical node** | A node in the minimal decomposition set for a range query |
| **Rebalance** | Structural adjustment after insert/remove preserving array/index invariants |

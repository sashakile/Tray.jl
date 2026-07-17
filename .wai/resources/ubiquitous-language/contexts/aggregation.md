# Aggregation Context

| Term | Definition |
|------|------------|
| **Tree** | An n-ary segment tree / hierarchical rollup structure |
| **Node** | Vertex in the tree holding a payload and child pointers |
| **Leaf** | Node with no children — atomic position or time bucket |
| **Internal node** | Node whose payload is computed by merging children's payloads |
| **Root** | Top-most node, aggregating the entire tree |
| **Branching factor** | `b` — maximum children per node |
| **Bottom-up** | Construction/update direction: children → parent → root |
| **Merge** | `combine(a, b) :: T` — associative, closed binary operation |
| **Canonical node** | A node in the minimal decomposition set for a range query |
| **Rebalance** | Structural adjustment after insert/remove to maintain tree properties |

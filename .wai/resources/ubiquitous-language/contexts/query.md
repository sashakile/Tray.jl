# Query Context

| Term | Definition |
|------|------------|
| **Range query** | Query over a contiguous range of leaf indices |
| **LOD** | Level of detail — tree depth at which a query is answered |
| **Target depth** | `d` — the LOD parameter for a query |
| **Canonical decomposition** | Minimal set of canonical nodes covering a query range |
| **Fractional depth** | Interpolated LOD between `floor(d)` and `ceil(d)` |
| **Interpolation** | Linear interpolation of payload fields before deriving statistics |
| **Quantile interpolation** | Interpolation of quantile function at matching probability levels |
| **Groupby axis** | Independent hierarchy (e.g. book, geography, factor bucket) |
| **Slice** | Query at the intersection of a groupby cut and a time range |
| **OLAP cube** | Conceptual model — multiple axes over the same leaf data |
| **Viewport** | Current visible range in an interactive dashboard context |

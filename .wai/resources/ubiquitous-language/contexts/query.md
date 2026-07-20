# Query Context

| Term | Definition |
|------|------------|
| **Range query** | Query over a contiguous range of leaf indices |
| **LOD** | Level of detail — tree depth at which a query is answered |
| **Target depth** | `d` — the LOD parameter for a query |
| **Canonical decomposition** | Minimal set of canonical nodes covering a query range |
| **Fractional depth** | Interpolated LOD between `floor(d)` and `ceil(d)` |
| **Interpolation** | Interpolation only through an explicitly declared affine projection |
| **Quantile interpolation** | Interpolation of quantile function at matching probability levels |
| **Axis** | Independent categorical, ordered, spatial, or other hierarchy |
| **Slice** | Query over the exact leaf-ID intersection of axis cuts |
| **OLAP cube** | Conceptual model — multiple axes over the same leaf data |
| **Viewport** | Current visible range in an interactive dashboard context |

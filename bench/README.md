| Benchmark | Baseline (0.2.0) | Current | Date | Δ |
|-----------|----------------|---------|------|---|
| Range query (10⁶ leaves, b=32, 5K range) | TBD | 0.0059 ms * | 2026-08-01 | TBD |
| Naive O(n) range (100K leaves, 5K range) | 0.0855 ms | 0.0855 ms | 2026-08-01 | — |
| Speedup vs naive | — | **14.4×** | 2026-08-01 | — |
| Point insert (100K leaves, b=32) | TBD | 0.444 ms | 2026-08-01 | TBD |
| Full tree fold (100K leaves) | TBD | 2.4 ns | 2026-08-01 | TBD |
| Construction (100K leaves, b=32) | TBD | 4.68 ms | 2026-08-01 | TBD |

*Note: 100K leaves, not 10⁶. The benchmark needs larger scale for the full VP metric.*
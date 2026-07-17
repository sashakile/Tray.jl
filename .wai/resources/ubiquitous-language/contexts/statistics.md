# Statistics Context

| Term | Definition |
|------|------------|
| **MonoidPayload** | Stored fields: count, sum, sumsq, min, max |
| **Derived statistic** | mean, variance, stddev — computed from MonoidPayload at read time |
| **Variance** | `sumsq / count - (sum / count)^2` |
| **Stddev** | `sqrt(variance)` |
| **ScenarioPayload** | Dense vector of P&L values over a fixed scenario set |
| **Quantile** | Value at a given probability threshold (derived from sorted scenario vector) |
| **Sketch** | Compressed distribution representation (e.g. t-digest) with configurable error bound |
| **Cornish-Fisher** | Moment-based tail estimation using skewness and kurtosis |
| **Exact mode** | Full scenario vector stored per node |
| **Approximate mode** | Sketch-based compression for nodes above a size threshold |

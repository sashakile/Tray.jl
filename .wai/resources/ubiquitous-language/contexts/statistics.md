# Statistics Context

| Term | Definition |
|------|------------|
| **ScalarSummary** | Convenience payload storing count, sum, sumsq, minimum, and maximum |
| **Derived statistic** | Mean, variance, and standard deviation computed at read time |
| **Variance** | `sumsq / count - (sum / count)^2` |
| **Stddev** | `sqrt(variance)` |
| **SamplePayload** | Dense vector over a fixed ordered sample-ID set |
| **AlignedArrayPayload** | Dense vector over fixed ordered dimension IDs |
| **Quantile** | Value at a probability threshold derived from a sorted sample |
| **Upper-tail mean** | Quantile integral above a probability, including fractional boundary mass |
| **Aligned-sum sketch** | Compressed representation preserving sample pairing with declared error bounds |
| **Cornish-Fisher** | Optional moment-based quantile estimation using skewness and kurtosis |
| **Exact mode** | Full sample vector stored per node |
| **Approximate mode** | Sketch-based compression for nodes above a size threshold |

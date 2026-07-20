# Optional Financial-Risk Context

These terms interpret domain-neutral core arrays and samples. They are not core
Tray payloads, revisions, or query semantics.

| Term | Definition |
|------|------------|
| **VaR** | Value-at-Risk — quantile-based risk measure at a given confidence level |
| **CVaR** | Conditional VaR / Expected Shortfall — average loss beyond VaR |
| **Parametric VaR** | VaR derived from `wᵀΣw` (variance-covariance approach) |
| **Component VaR** | Contribution of a sub-portfolio to total VaR |
| **Marginal VaR** | Sensitivity of VaR to a small change in position weight |
| **Factor model** | Scenario P&L computed as `(exposure) · (factor scenario matrix)` |
| **Factor covariance** | `Σ` — covariance matrix of factor returns |
| **Exposure vector** | `w` — factor exposure for a given node |
| **Stress test** | Scenario reweighting of a subtree |
| **Historical window** | Rolling time window for historical simulation |
| **Diversification** | Non-additive nature of VaR across sub-portfolios |

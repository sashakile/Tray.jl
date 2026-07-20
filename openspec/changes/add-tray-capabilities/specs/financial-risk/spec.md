## ADDED Requirements

### Requirement: FIN-1 Loss quantiles and Expected Shortfall
Where financial loss interpretation is enabled, the adapter SHALL interpret aligned profit-and-loss sample `P` as losses `L=-P`, define VaR at confidence `c` as core quantile `q_c(L)`, and define Expected Shortfall as the core upper-tail mean with fractional boundary mass.

#### Scenario: Derive loss-tail measures
- **WHEN** aligned P&L samples and valid confidence are supplied
- **THEN** VaR and Expected Shortfall equal the corresponding core loss-sample statistics

### Requirement: FIN-2 Gaussian factor risk
Where Gaussian factor risk is enabled, the adapter SHALL interpret REQ-16's quadratic projection as portfolio variance and compute zero-mean Gaussian VaR `Φ⁻¹(c)sqrt(wᵀMw)` for `c` in `(0.5,1)`.

#### Scenario: Derive Gaussian VaR
- **WHEN** valid aligned factor inputs and confidence are supplied
- **THEN** the adapter scales the square root of the core quadratic projection by `Φ⁻¹(c)`

### Requirement: FIN-3 Contribution risk
Where contribution risk is enabled, the adapter SHALL scale REQ-17's normalized covariance contribution by `Φ⁻¹(c)` for marginal VaR and by node scale for component VaR.

#### Scenario: Derive marginal and component VaR
- **WHEN** valid aligned loss samples, confidence, and node scale are supplied
- **THEN** both values match the specified scaling of the core covariance contribution

### Requirement: FIN-4 Factor-scenario P&L
Where factor-scenario generation is enabled, the adapter SHALL interpret REQ-28's aligned matrix projection as scenario P&L and require exact ordered factor-ID alignment.

#### Scenario: Generate scenario P&L
- **WHEN** aligned exposures and factor scenarios are supplied
- **THEN** generated P&L equals the core matrix projection

### Requirement: FIN-5 Financial moment estimate
Where moment-based financial tail estimation is enabled, the adapter SHALL apply REQ-30 to loss moments, report Cornish-Fisher VaR as approximate, and expose the near-Gaussian assumption.

#### Scenario: Estimate financial tail risk
- **WHEN** valid loss moments and confidence are supplied
- **THEN** the adapter returns approximate Cornish-Fisher VaR with its assumption

### Requirement: FIN-6 Historical simulation
Where historical financial simulation is enabled, the adapter SHALL interpret REQ-37 rolling samples as historical scenarios while retaining core dataset-revision and atomic-publication guarantees.

#### Scenario: Advance historical scenarios
- **WHEN** the historical window advances
- **THEN** changed financial samples publish under exactly one new core dataset revision

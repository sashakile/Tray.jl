# Tray.FinancialRisk — Optional financial risk adapter (FIN-1 through FIN-6).
#
# Interprets core Tray analytics in financial terminology: P&L samples, VaR,
# Expected Shortfall, Gaussian factor risk, contribution risk, scenario P&L,
# and Cornish-Fisher VaR.
#
# Loading this module is optional — core Tray loads and tests without it.

module FinancialRisk

import ..Tray: ScalarSchema, ScalarSummary, Tree, root, leaf_count, range_query
import ..Tray.SampleAnalytics:
    SamplePayload,
    advance_window!,
    exact_quantile,
    exact_tail_mean,
    project_samples,
    AlignedProjectionError,
    moment_quantile,
    MomentQuantileResult
import ..Tray.AlignedArray:
    AlignedArrayPayload,
    quadratic_projection,
    normalized_covariance_contribution,
    AlignedArrayError

export fin_var,
    fin_expected_shortfall,
    fin_gaussian_var,
    fin_marginal_var,
    fin_component_var,
    fin_scenario_pnl,
    fin_moment_var

# ---------------------------------------------------------------------------
# Utility: normal inverse CDF
# ---------------------------------------------------------------------------

function _norminv(c::Real)
    0 < c < 1 || throw(DomainError(c, "confidence must be in (0, 1)"))
    p = Float64(c)

    # Central region coefficients (Acklam rational approximation)
    a = [
        -39.69683088665369,
        220.9460984245205,
        -275.9285104469687,
        138.3577518672690,
        -30.66479806614716,
        2.506628277459239,
    ]
    b = [
        -54.47609879822406,
        161.5858368580409,
        -155.6989798598866,
        66.80131188771972,
        -13.28068155288572,
        1.0,
    ]

    # Tail region coefficients (Abramowitz & Stegun 26.2.23)
    c0, c1, c2 = 2.515517, 0.802853, 0.010328
    d0, d1, d2 = 1.432788, 0.189269, 0.001308

    if p < 0.02425
        q = sqrt(-2.0 * log(p))
        return Float64(-(q - (c0 + c1*q + c2*q^2) / (1 + d0*q + d1*q^2 + d2*q^3)))
    elseif p < 0.97575
        q = p - 0.5
        r = q * q
        num = (((((a[1]*r + a[2])*r + a[3])*r + a[4])*r + a[5])*r + a[6])*q
        den = (((((b[1]*r + b[2])*r + b[3])*r + b[4])*r + b[5])*r + b[6])
        return Float64(num / den)
    else
        q = sqrt(-2.0 * log(1.0 - p))
        return Float64(q - (c0 + c1*q + c2*q^2) / (1 + d0*q + d1*q^2 + d2*q^3))
    end
end

# ---------------------------------------------------------------------------
# FIN-1: Loss quantiles and Expected Shortfall
# ---------------------------------------------------------------------------

function fin_var(samples::Vector{T}, confidence::Real) where {T}
    0 < confidence < 1 || throw(DomainError(confidence, "confidence must be in (0, 1)"))
    loss = [-s for s in samples]
    return exact_quantile(loss, confidence)
end

function fin_expected_shortfall(samples::Vector{T}, confidence::Real) where {T}
    0 < confidence < 1 || throw(DomainError(confidence, "confidence must be in (0, 1)"))
    loss = [-s for s in samples]
    return exact_tail_mean(loss, confidence)
end

# ---------------------------------------------------------------------------
# FIN-2: Gaussian factor risk
# ---------------------------------------------------------------------------

function fin_gaussian_var(
    weights::AlignedArrayPayload{T},
    factor_covariance::Matrix{T},
    confidence::Real,
) where {T}
    0.5 < confidence < 1 ||
        throw(DomainError(confidence, "Gaussian VaR requires confidence in (0.5, 1)"))
    variance = quadratic_projection(weights, factor_covariance)
    variance >= 0 || throw(DomainError(variance, "portfolio variance must be non-negative"))
    z = _norminv(confidence)
    return z * sqrt(variance)
end

# ---------------------------------------------------------------------------
# FIN-3: Contribution risk
# ---------------------------------------------------------------------------

function fin_marginal_var(cov_contribution::T, confidence::Real) where {T}
    0 < confidence < 1 || throw(DomainError(confidence, "confidence must be in (0, 1)"))
    z = _norminv(confidence)
    return z * cov_contribution
end

function fin_component_var(cov_contribution::T, node_scale::T, confidence::Real) where {T}
    0 < confidence < 1 || throw(DomainError(confidence, "confidence must be in (0, 1)"))
    z = _norminv(confidence)
    return z * cov_contribution * node_scale
end

# ---------------------------------------------------------------------------
# FIN-4: Factor-scenario P&L
# ---------------------------------------------------------------------------

function fin_scenario_pnl(weights::Vector{T}, factor_scenarios::Matrix{T}) where {T}
    return project_samples(weights, factor_scenarios)
end

# ---------------------------------------------------------------------------
# FIN-5: Financial moment estimate
# ---------------------------------------------------------------------------

function fin_moment_var(
    confidence::Real,
    mean::Real,
    variance::Real,
    skewness::Real,
    excess_kurtosis::Real,
)
    0 < confidence < 1 || throw(DomainError(confidence, "confidence must be in (0, 1)"))
    # For loss L = -P, the mean shifts sign
    return moment_quantile(confidence, -mean, variance, skewness, excess_kurtosis)
end

function fin_moment_var(confidence::Real, summary::ScalarSummary{T}) where {T}
    0 < confidence < 1 || throw(DomainError(confidence, "confidence must be in (0, 1)"))
    # For loss L = -P: mean flips sign, odd central moments flip sign
    n = T(summary.count)
    μ = summary.sum / n
    var = (summary.sumsq / n) - μ^2
    var > 0 || return moment_quantile(confidence, -μ, var, 0.0, 0.0)

    if !isnothing(summary.m3) && !isnothing(summary.m4)
        m3_raw = summary.m3 / n
        m4_raw = summary.m4 / n
        # Central third moment: E[(X-μ)³] = E[X³] - 3·μ·E[X²] + 2·μ³
        μ2 = summary.sumsq / n
        skew_raw = (m3_raw - 3 * μ * μ2 + 2 * μ^3) / var^1.5
        # For loss L=-P: skew(L) = -skew(P)
        kurt_raw = (m4_raw - 4 * μ * m3_raw + 6 * μ^2 * μ2 - 3 * μ^4) / var^2 - 3.0
        return moment_quantile(confidence, -μ, var, -skew_raw, kurt_raw)
    end
    return moment_quantile(confidence, -μ, var, 0.0, 0.0)
end

end # module FinancialRisk

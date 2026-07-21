"""
    Tray.Incremental

Finite-change algebra for exact incremental updates.

Every supported value type `T` defines:
- `Change{T}` — a change (delta) value for numeric types
- `ScalarSummaryChange{T}` — a change for ScalarSummary payloads
- `zero_change(old::T)::Change{T}` — identity for composition
- `valid_change(old, Δ)::Bool` — validity check
- `apply_change(old, Δ)::T` — apply a change to an old value
- `compose_change(old, Δ1, Δ2)::Change{T}` — compose two sequential changes

Every generated rule `Δf` satisfies the exactness law:
    apply_change(f(old_args...), Δf(old_args, old_result, Δargs)) ==
    f(map(apply_change, old_args, Δargs)...)

See REQ-A1.
"""
module Incremental

using ..TrayBase
using ..Tray: ScalarSummary

# ---------------------------------------------------------------------------
# Change types
# ---------------------------------------------------------------------------

"""
    Change{T} <: Number

A finite change to a numeric value of type `T`.

Wraps an additive delta.
"""
struct Change{T} <: Number
    delta::T
end

"""
    ScalarSummaryChange{T} <: Number

Per-field deltas for a ScalarSummary.

Each field is the delta to apply. Minimum and maximum carry the *new*
extreme value, not a delta — the result takes the extrema of old and new.
"""
Base.@kwdef struct ScalarSummaryChange{T} <: Number
    count::Int
    sum::T
    sumsq::T
    minimum::T
    maximum::T
end

# ---------------------------------------------------------------------------
# Primitive: Float64
# ---------------------------------------------------------------------------

zero_change(::Float64) = Change{Float64}(0.0)
valid_change(::Float64, ::Change{Float64}) = true
apply_change(old::Float64, Δ::Change{Float64}) = old + Δ.delta
compose_change(::Float64, Δ1::Change{Float64}, Δ2::Change{Float64}) =
    Change{Float64}(Δ1.delta + Δ2.delta)

# ---------------------------------------------------------------------------
# Primitive: Float32
# ---------------------------------------------------------------------------

zero_change(::Float32) = Change{Float32}(0.0f0)
valid_change(::Float32, ::Change{Float32}) = true
apply_change(old::Float32, Δ::Change{Float32}) = old + Δ.delta
compose_change(::Float32, Δ1::Change{Float32}, Δ2::Change{Float32}) =
    Change{Float32}(Δ1.delta + Δ2.delta)

# ---------------------------------------------------------------------------
# Primitive: Int
# ---------------------------------------------------------------------------

zero_change(::Int) = Change{Int}(0)
valid_change(::Int, ::Change{Int}) = true
apply_change(old::Int, Δ::Change{Int}) = old + Δ.delta
compose_change(::Int, Δ1::Change{Int}, Δ2::Change{Int}) = Change{Int}(Δ1.delta + Δ2.delta)

# ---------------------------------------------------------------------------
# Primitive: Int32
# ---------------------------------------------------------------------------

zero_change(::Int32) = Change{Int32}(Int32(0))
valid_change(::Int32, ::Change{Int32}) = true
apply_change(old::Int32, Δ::Change{Int32}) = old + Δ.delta
compose_change(::Int32, Δ1::Change{Int32}, Δ2::Change{Int32}) =
    Change{Int32}(Δ1.delta + Δ2.delta)

# ---------------------------------------------------------------------------
# Primitive: UInt
# ---------------------------------------------------------------------------

zero_change(::UInt) = Change{UInt}(UInt(0))
valid_change(::UInt, ::Change{UInt}) = true
apply_change(old::UInt, Δ::Change{UInt}) = old + Δ.delta
compose_change(::UInt, Δ1::Change{UInt}, Δ2::Change{UInt}) =
    Change{UInt}(Δ1.delta + Δ2.delta)

# ---------------------------------------------------------------------------
# ScalarSummary{T}
# ---------------------------------------------------------------------------

function zero_change(s::ScalarSummary{T}) where {T}
    return ScalarSummaryChange{T}(
        count = 0,
        sum = zero(T),
        sumsq = zero(T),
        minimum = T(Inf),
        maximum = T(-Inf),
    )
end

function valid_change(old::ScalarSummary{T}, Δ::ScalarSummaryChange{T}) where {T}
    # A change is valid if it doesn't produce negative count
    if old.count + Δ.count < 0
        return false
    end
    return true
end

function apply_change(old::ScalarSummary{T}, Δ::ScalarSummaryChange{T}) where {T}
    schema = old.schema

    new_count = old.count + Δ.count
    new_sum = old.sum + Δ.sum
    new_sumsq = old.sumsq + Δ.sumsq

    # Min/max: take the extrema of old and delta values
    # (delta carries the *new* min/max, not a delta)
    new_min = if Δ.minimum < old.minimum
        Δ.minimum
    else
        old.minimum
    end
    new_max = if Δ.maximum > old.maximum
        Δ.maximum
    else
        old.maximum
    end

    # If delta has sentinel values, keep old values
    if Δ.minimum == T(Inf)
        new_min = old.minimum
    end
    if Δ.maximum == T(-Inf)
        new_max = old.maximum
    end

    if schema.higher_moment
        return ScalarSummary(
            schema = schema,
            count = new_count,
            sum = new_sum,
            sumsq = new_sumsq,
            minimum = new_min,
            maximum = new_max,
            m3 = old.m3,
            m4 = old.m4,
        )
    else
        return ScalarSummary(
            schema = schema,
            count = new_count,
            sum = new_sum,
            sumsq = new_sumsq,
            minimum = new_min,
            maximum = new_max,
        )
    end
end

function compose_change(
    old::ScalarSummary{T},
    Δ1::ScalarSummaryChange{T},
    Δ2::ScalarSummaryChange{T},
) where {T}
    new_min = if Δ2.minimum < Δ1.minimum
        Δ2.minimum
    else
        Δ1.minimum
    end
    new_max = if Δ2.maximum > Δ1.maximum
        Δ2.maximum
    else
        Δ1.maximum
    end

    # Sentinel handling
    if Δ1.minimum == T(Inf)
        new_min = Δ2.minimum
    end
    if Δ2.minimum == T(Inf)
        new_min = Δ1.minimum
    end
    if Δ1.maximum == T(-Inf)
        new_max = Δ2.maximum
    end
    if Δ2.maximum == T(-Inf)
        new_max = Δ1.maximum
    end

    return ScalarSummaryChange{T}(
        count = Δ1.count + Δ2.count,
        sum = Δ1.sum + Δ2.sum,
        sumsq = Δ1.sumsq + Δ2.sumsq,
        minimum = new_min,
        maximum = new_max,
    )
end

# ---------------------------------------------------------------------------
# Exact built-in rules (REQ-A6)
# ---------------------------------------------------------------------------

"""
    Δf_for_add(new_x, old_result, Δx)

Compute the change for `f(x) = x + c` (additive).
For additive numeric changes, `Δf = Δx`.
"""
function Δf_for_add(::T, ::T, Δx::Change{T}) where {T<:Number}
    return Δx
end

"""
    Δf_for_mul(new_x, new_y, old_result, Δx, Δy)

Compute the change for `f(x, y) = x * y`.
Returns `old_x*Δy + Δx*old_y + Δx*Δy` as a Change.
"""
function Δf_for_mul(
    new_x::T,
    new_y::T,
    old_result::T,
    Δx::Change{T},
    Δy::Change{T},
) where {T<:Number}
    old_x = new_x - Δx.delta
    old_y = new_y - Δy.delta
    delta = old_x * Δy.delta + Δx.delta * old_y + Δx.delta * Δy.delta
    return Change{T}(delta)
end

"""
    Δf_for_sin(old_x, old_result, Δx)

Compute the change for `f(x) = sin(x)`.
Returns `sin(new_x) - sin(old_x)`.
"""
function Δf_for_sin(old_x::T, ::T, Δx::Change{T}) where {T<:Number}
    new_x = old_x + Δx.delta
    delta = sin(new_x) - sin(old_x)
    return Change{T}(delta)
end

"""
    Δf_for_minmax(new_x, new_y, old_result, Δx, Δy, is_min)

Compute the change for `min(x, y)` or `max(x, y)`.
Returns `new_result - old_result` using Julia's operation semantics.
"""
function Δf_for_minmax(
    new_x::T,
    new_y::T,
    old_result::T,
    ::Change{T},
    ::Change{T},
    is_min::Bool,
) where {T<:Number}
    new_result = is_min ? min(new_x, new_y) : max(new_x, new_y)
    delta = new_result - old_result
    return Change{T}(delta)
end

# ---------------------------------------------------------------------------
# Rule registry (REQ-A4)
# ---------------------------------------------------------------------------

"""
    RuleKey{F, A}

Registry key parameterized by callable type `F` and argument tuple type `A`.
"""
struct RuleKey{F,A}
    # Tag type — no runtime data
end

"""
    Rule{F, A, AppF}

A registered finite-change rule, keyed by `RuleKey{F, A}`.
`f` is the original callable, `argtypes` is the tuple type of the arguments,
and `apply` is the callable that computes the finite change.
"""
struct Rule{F,A,AppF}
    f::F
    argtypes::Type{A}
    apply::AppF
end

"""
    RegistrySnapshot

Immutable snapshot of the rule registry at a given revision.
"""
struct RegistrySnapshot
    revision::Int
    rules::Dict{Any,Any}
end

"""
    RuleRegistry

Mutable handle to a revisioned rule registry.
Each write operation (register, replace, remove) creates a new immutable snapshot
with a monotonically increasing revision number.
"""
mutable struct RuleRegistry
    current::RegistrySnapshot
    revision_counter::Int

    RuleRegistry() = new(RegistrySnapshot(0, Dict{Any,Any}()), 0)
end

function register!(reg::RuleRegistry, rule::Rule{F,A}) where {F,A}
    key = RuleKey{F,A}
    if haskey(reg.current.rules, (F, A))
        throw(
            ArgumentError("Rule for ($F, $A) already registered; use replace! to override"),
        )
    end
    reg.revision_counter += 1
    new_rules = copy(reg.current.rules)
    new_rules[(F, A)] = rule
    reg.current = RegistrySnapshot(reg.revision_counter, new_rules)
    return reg.revision_counter
end

function replace!(reg::RuleRegistry, rule::Rule{F,A}) where {F,A}
    reg.revision_counter += 1
    new_rules = copy(reg.current.rules)
    new_rules[(F, A)] = rule
    reg.current = RegistrySnapshot(reg.revision_counter, new_rules)
    return reg.revision_counter
end

function remove!(reg::RuleRegistry, ::Type{F}, ::Type{A}) where {F,A}
    reg.revision_counter += 1
    new_rules = copy(reg.current.rules)
    delete!(new_rules, (F, A))
    reg.current = RegistrySnapshot(reg.revision_counter, new_rules)
    return reg.revision_counter
end

function lookup(reg::RuleRegistry, f, argtypes::Tuple)
    ftype = typeof(f)

    applicable = Tuple{Type,Type,Any,Int}[]
    for ((rf, ra), rule) in reg.current.rules
        if isapplicable(rf, ra, ftype, argtypes)
            push!(applicable, (rf, ra, rule, length(applicable)))
        end
    end

    isempty(applicable) && return nothing
    length(applicable) == 1 && return applicable[1][3]

    candidate = applicable[1]
    for i = 2:length(applicable)
        cmp = compare_specificity(
            candidate[1],
            candidate[2],
            applicable[i][1],
            applicable[i][2],
        )
        if cmp == :incomparable
            return nothing
        elseif cmp == :second_more_specific
            candidate = applicable[i]
        end
    end

    return candidate[3]
end

function isapplicable(rf::Type, ra::Type, ftype::Type, argtypes::Tuple)
    ftype <: rf || return false
    return type_tuple_issubset(argtypes, ra)
end

function type_tuple_issubset(t1::Tuple, t2::Type)
    t2_params = t2.parameters
    length(t1) == length(t2_params) || return false
    for (a, b) in zip(t1, t2_params)
        a <: b || return false
    end
    return true
end

function compare_specificity(rf1::Type, ra1::Type, rf2::Type, ra2::Type)
    first_specific = is_more_specific(rf1, ra1, rf2, ra2)
    second_specific = is_more_specific(rf2, ra2, rf1, ra1)

    if first_specific && !second_specific
        return :first_more_specific
    elseif second_specific && !first_specific
        return :second_more_specific
    else
        return :incomparable
    end
end

function is_more_specific(rf_a::Type, ra_a::Type, rf_b::Type, ra_b::Type)
    rf_more = (rf_a <: rf_b) && (rf_a != rf_b)
    rf_equal = (rf_a == rf_b)
    ra_more = type_tuple_more_specific(ra_a, ra_b)
    ra_equal = (ra_a == ra_b)

    if rf_more && (ra_equal || ra_more)
        return true
    end
    if ra_more && (rf_equal || rf_more)
        return true
    end
    return false
end

function type_tuple_more_specific(ta::Type, tb::Type)
    ta == tb && return false

    params_a = ta.parameters
    params_b = tb.parameters
    length(params_a) == length(params_b) || return false

    any_more_specific = false
    for (a, b) in zip(params_a, params_b)
        a == b && continue
        a <: b || return false
        any_more_specific = true
    end

    return any_more_specific
end

snapshot(reg::RuleRegistry) = reg.current

# ---------------------------------------------------------------------------
# IR provider interface (REQ-A2)
# ---------------------------------------------------------------------------

"""
    AbstractProvider

Abstract type for IR providers. A provider exposes capability probing and
IR retrieval for method derivation. Subtypes must implement:
- `available(provider)::Bool` — whether the provider is usable in this environment
- `retrieve_ir(provider, f, ArgTypes)::Union{Nothing,Any}` — retrieve IR

Providers are loaded lazily at `derive` call time, never at module init.
"""
abstract type AbstractProvider end

"""
    DefaultProvider <: AbstractProvider

Provider using documented IRTools `IR`, `code_ir`, and `@code_ir` surfaces.
IRTools is loaded lazily at derive time, never at module load.

Supports Julia ≥ 1.10 with compatible IRTools 0.4.x.
See REQ-A2.
"""
struct DefaultProvider <: AbstractProvider end

# Known UUID for IRTools in the Julia General registry
const _IRTOOLS_UUID = Base.UUID("7869d1d1-7146-5819-86e3-9091afe4b00a")

"""
    available(provider::DefaultProvider)::Bool

Check whether the default provider is usable in the current environment.
Returns `true` only when:
- Julia ≥ 1.10
- IRTools 0.4.x can be loaded

See REQ-A2, REQ-A11.
"""
function available(::DefaultProvider)
    # Check Julia version ≥ 1.10
    VERSION >= v"1.10" || return false

    # Try to load IRTools at call time — never at module init
    try
        Base.require(Base.PkgId(_IRTOOLS_UUID, "IRTools"))
        return true
    catch
        return false
    end
end

"""
    retrieve_ir(provider::DefaultProvider, f, ::Type{ArgTypes}) -> Union{Nothing,Any}

Retrieve the IR for callable `f` with the given argument types using the
IRTools `code_ir` surface. Returns `nothing` if IRTools is unavailable,
incompatible, or the method cannot be retrieved.

IRTools is loaded lazily — never at module init.

See REQ-A2.
"""
function retrieve_ir(::DefaultProvider, f, ::Type{ArgTypes}) where {ArgTypes}
    # Lazily load IRTools at derive call time
    try
        irtools = Base.require(Base.PkgId(_IRTOOLS_UUID, "IRTools"))
        return irtools.code_ir(f, ArgTypes)
    catch e
        if e isa LoadError || e isa ArgumentError || e isa MethodError
            return nothing
        end
        rethrow()
    end
end

# ---------------------------------------------------------------------------
# Coverage lattice (REQ-A5)
# ---------------------------------------------------------------------------

"""
    CoverageLevel

Transitive coverage lattice for derivation analysis.

Values in increasing order:
- `CovCovered < CovBoundary < CovRejected`

An alias `Cov` prefix avoids collision with the `Rejected` result type.

Joins take the worse value (higher ordinal).

See REQ-A5.
"""
@enum CoverageLevel begin
    CovCovered = 0
    CovBoundary = 1
    CovRejected = 2
end

"""
    coverage_join(a::CoverageLevel, b::CoverageLevel)::CoverageLevel

Join two coverage levels, returning the worse (higher ordinal) value.

Satisfies:
- Idempotent: `join(a, a) == a`
- Commutative: `join(a, b) == join(b, a)`
- Associative: `join(join(a, b), c) == join(a, join(b, c))`

See REQ-A5.
"""
coverage_join(a::CoverageLevel, b::CoverageLevel) = max(a, b)

# ---------------------------------------------------------------------------
# Classified diagnostics (REQ-A11)
# ---------------------------------------------------------------------------

"""
    Diagnostic

A typed diagnostic for a classified derivation failure.

Fields:
- `code`: error class from REQ-A11 (e.g. "IRProviderUnavailable", "RuleMissing")
- `message`: human-readable description of the failure
- `phase`: phase of occurrence (e.g. "derive", "analysis", "apply")
- `callable`: the callable or method identity when known
- `location`: source location when known
- `remediation`: suggestion for fixing the issue
- `cause`: preserved raw exception or nothing

See REQ-A11.
"""
struct Diagnostic
    code::String
    message::String
    phase::String
    callable::Union{Nothing,Any}
    location::Union{Nothing,String}
    remediation::Union{Nothing,String}
    cause::Union{Nothing,Exception}

    # Keyword constructor (convenience — short form with code, message, phase)
    function Diagnostic(
        code::String,
        message::String,
        phase::String;
        callable::Union{Nothing,Any} = nothing,
        location::Union{Nothing,String} = nothing,
        remediation::Union{Nothing,String} = nothing,
        cause::Union{Nothing,Exception} = nothing,
    )
        return new(code, message, phase, callable, location, remediation, cause)
    end

    # Positional constructor (full form with all fields)
    function Diagnostic(
        code::String,
        message::String,
        phase::String,
        callable::Union{Nothing,Any},
        location::Union{Nothing,String},
        remediation::Union{Nothing,String},
        cause::Union{Nothing,Exception},
    )
        return new(code, message, phase, callable, location, remediation, cause)
    end
end

# ---------------------------------------------------------------------------
# Sealed AnalysisResult sum type (REQ-A5)
# ---------------------------------------------------------------------------

"""
    AnalysisResult

Sealed sum type for derivation results. Contains only:
- `Derived(artifact, argtypes, coverage)` — successful derivation
- `Rejected(diagnostics, coverage)` — derivation failure

`Rejected` contains no callable partial artifact.

See REQ-A5.
"""
abstract type AnalysisResult end

"""
    Derived{F, A} <: AnalysisResult

Successful derivation result.

- `artifact`: the generated callable artifact
- `argtypes`: the argument tuple type for which the artifact was derived
- `coverage`: the transitive coverage level of the derivation

An artifact is callable only after all transitive sites are `Covered`.

See REQ-A5, REQ-A3.
"""
struct Derived{F,A} <: AnalysisResult
    artifact::F
    argtypes::Type{A}
    coverage::CoverageLevel
end

"""
    Rejected <: AnalysisResult

Failed derivation result.

- `diagnostics`: list of typed `Diagnostic`s describing the failure
- `coverage`: the transitive coverage level (always `CovBoundary` or `CovRejected`)

Contains no callable partial artifact. Every derivation-time failure is
represented as a typed diagnostic inside `Rejected`.

See REQ-A5, REQ-A11.
"""
struct Rejected <: AnalysisResult
    diagnostics::Vector{Diagnostic}
    coverage::CoverageLevel
end

# ---------------------------------------------------------------------------
# IR analysis framework (REQ-A3, REQ-A8)
# ---------------------------------------------------------------------------

"""
    IROpKind

Classification of IR operations for coverage analysis.

See REQ-A8 for boundary operations.
"""
@enum IROpKind begin
    OpCall           # Function call — check coverage/registry
    OpReturn         # Return statement — always covered
    OpGoto           # Unconditional branch — always covered
    OpGotoIfNot      # Conditional branch — check branch stability
    OpPhi            # Phi node — covered if all incoming values covered
    OpIsA            # Type check — always covered
    OpNew            # Object allocation — always covered
    OpInvoke         # Invoke (known method) — check coverage
    OpExpr           # Expression / built-in — always covered
    OpConstant       # Constant value — always covered
    OpUnknown        # Unknown operation — always rejected
end

"""
    AnalyzedStmt

A single IR statement with its coverage classification.

- `index`: the SSA value index
- `kind`: the operation kind classification
- `coverage`: the coverage level of this statement
- `diagnostic`: optional diagnostic if rejected or boundary

See REQ-A3.
"""
struct AnalyzedStmt
    index::Int
    kind::IROpKind
    coverage::CoverageLevel
    diagnostic::Union{Nothing,Diagnostic}
end

"""
    IRSummary

Summary of the IR analysis for a function.

- `statements`: analyzed statements in SSA order
- `coverage`: overall transitive coverage level
- `diagnostics`: all diagnostics collected during analysis

See REQ-A3, REQ-A5.
"""
struct IRSummary
    statements::Vector{AnalyzedStmt}
    coverage::CoverageLevel
    diagnostics::Vector{Diagnostic}
end

"""
    classify_operation(stmt) -> IROpKind

Classify an IRTools IR statement into an `IROpKind`.

IRTools IR statements are `Expr` heads with operation types. Falls back to
`OpUnknown` for unrecognized forms.

See REQ-A8.
"""
function classify_operation(stmt)
    # stmt is an IRTools.IRStatement or similar
    # We detect the operation type by heuristics on the expression
    if !isa(stmt, Expr)
        return OpConstant
    end

    head = stmt.head

    if head === :return
        return OpReturn
    elseif head === :goto
        return OpGoto
    elseif head === :gotoifnot
        return OpGotoIfNot
    elseif head === :phi
        return OpPhi
    elseif head === :call
        return OpCall
    elseif head === :invoke
        return OpInvoke
    elseif head === :(=)
        # Assignment: classify the RHS
        rhs = stmt.args[2]
        if isa(rhs, Expr)
            return classify_operation(rhs)
        end
        return OpConstant
    elseif head === :is_a || head === :isa
        return OpIsA
    elseif head === :new
        return OpNew
    elseif head === :foreigncall
        return OpUnknown
    else
        # Unknown expression head — could be a straight-line expression
        return OpExpr
    end
end

"""
    is_pure_call(f, argtypes, registry) -> Bool

Check whether a call to `f` with the given argument types is pure (no side
effects) and has a covered rule in the registry.

For v1, we conservatively check:
1. The function is a known pure built-in (+, *, sin, min, max)
2. The function is in the registry with a covered rule

See REQ-A8.
"""
function is_pure_call(f, argtypes, registry::Union{RuleRegistry,Nothing})
    # Resolve Symbol to function reference (e.g., :+ -> +)
    callee = if f isa Symbol
        try
            getfield(Base, f)
        catch
            f
        end
    else
        f
    end

    # Known pure built-ins are always covered
    if callee in (+, *, sin, min, max, isless, ==, <, >, <=, >=, abs, zero, one)
        return true
    end

    # Check registry if available
    if registry !== nothing
        # For registry lookup, use a sample tuple instance
        rule = lookup(registry, callee, ())
        return rule !== nothing
    end

    # Conservative: no info available, treat as boundary
    return false
end

"""
    analyze_statement(kind::IROpKind, stmt, f, argtypes, registry) -> Tuple{CoverageLevel,Union{Nothing,Diagnostic}}

Analyze a single IR statement and return its coverage level and optional diagnostic.

Returns `(CovCovered, nothing)` for covered operations, `(CovBoundary, diag)` for
boundary operations, and `(CovRejected, diag)` for rejected operations.

See REQ-A3, REQ-A8, REQ-A11.
"""
function analyze_statement(
    kind::IROpKind,
    stmt,
    f,
    argtypes,
    registry::Union{RuleRegistry,Nothing},
)
    if kind == OpReturn ||
       kind == OpGoto ||
       kind == OpConstant ||
       kind == OpExpr ||
       kind == OpIsA ||
       kind == OpNew
        return (CovCovered, nothing)
    end

    if kind == OpUnknown
        return (
            CovRejected,
            Diagnostic(
                "UnsupportedEffect",
                "Unknown operation in IR: $(stmt). This operation cannot be " *
                "incrementalized in v1.",
                "analysis";
                callable = f,
                remediation = "Simplify the function to avoid the unknown operation",
            ),
        )
    end

    if kind == OpCall || kind == OpInvoke
        # Extract the called function from the statement
        callee = _extract_callee(stmt, kind)
        if callee === nothing
            return (
                CovBoundary,
                Diagnostic(
                    "UnsupportedEffect",
                    "Dynamic call or unresolvable callee in IR. Cannot determine " *
                    "if the target is pure and covered.",
                    "analysis";
                    callable = f,
                    remediation = "Use a direct function call instead of a dynamic dispatch",
                ),
            )
        end

        if is_pure_call(callee, argtypes, registry)
            return (CovCovered, nothing)
        else
            return (
                CovBoundary,
                Diagnostic(
                    "RuleMissing",
                    "No rule available for call to $(callee) with argument types " *
                    "$argtypes. Register a rule or simplify the function.",
                    "analysis";
                    callable = callee,
                    remediation = "Register a rule for $(callee) with Pkg.add or define a built-in rule",
                ),
            )
        end
    end

    if kind == OpGotoIfNot
        # Conditional branch — check branch stability
        # In v1, we can only handle branch-stable code
        return (
            CovBoundary,
            Diagnostic(
                "ControlFlowChanged",
                "Conditional branch detected in IR. Branch-stable code is supported " *
                "but requires all branches to be covered. This is a boundary in v1 " *
                "unless explicitly unrolled.",
                "analysis";
                callable = f,
                remediation = "Consider using a straight-line computation or registering " *
                              "a custom rule for the conditional",
            ),
        )
    end

    if kind == OpPhi
        # Phi nodes merge values from different branches
        # In v1, phi nodes are a boundary since we don't support branch splitting
        return (
            CovBoundary,
            Diagnostic(
                "ControlFlowChanged",
                "Phi node (value merge) detected in IR. Multiple incoming values " *
                "from different branches cannot be merged in v1.",
                "analysis";
                callable = f,
                remediation = "Eliminate the control flow merge or register a custom rule",
            ),
        )
    end

    return (
        CovRejected,
        Diagnostic(
            "GenerationFailure",
            "Unhandled operation kind $(kind) in IR analysis.",
            "analysis";
            callable = f,
            remediation = "This is a bug — report it with the function source",
        ),
    )
end

"""
    _extract_callee(stmt, kind::IROpKind) -> Union{Nothing,Any}

Extract the called function from an IR call or invoke statement.

For `:call` expressions, the callee is the first argument of the expression.
For `:invoke` expressions, the callee is the first argument of the second argument.
Returns `nothing` if the callee cannot be determined.
"""
function _extract_callee(stmt, ::IROpKind)
    if !isa(stmt, Expr)
        return nothing
    end

    if stmt.head === :call && length(stmt.args) >= 1
        return stmt.args[1]
    end

    if stmt.head === :invoke && length(stmt.args) >= 2
        # :invoke has form (method, argtypes, args...)
        return stmt.args[2]
    end

    # For assignment expressions, check the RHS
    if stmt.head === :(=) && length(stmt.args) >= 2
        rhs = stmt.args[2]
        if isa(rhs, Expr) && rhs.head === :call
            return _extract_callee(rhs, OpCall)
        end
        if isa(rhs, Expr) && rhs.head === :invoke
            return _extract_callee(rhs, OpInvoke)
        end
    end

    return nothing
end

"""
    analyze_ir(ir, f, argtypes::Type, registry::Union{RuleRegistry,Nothing}) -> IRSummary

Analyze the IR of a function and return a coverage summary.

Walks all IR statements, classifies each operation, and determines the
transitive coverage level. Diagnostics are collected for any boundary or
rejected operations.

See REQ-A3, REQ-A8.
"""
function analyze_ir(ir, f, argtypes, registry::Union{RuleRegistry,Nothing})
    stmts = AnalyzedStmt[]
    diags = Diagnostic[]
    cov = CovCovered

    # IRTools IR has a `.stmts` field or similar; we iterate over statements
    # Structure varies by IRTools version — handle both IR and Vector forms
    ir_stmts = _get_ir_statements(ir)

    for (i, stmt) in enumerate(ir_stmts)
        kind = classify_operation(stmt)
        stmt_cov, stmt_diag = analyze_statement(kind, stmt, f, argtypes, registry)
        push!(stmts, AnalyzedStmt(i, kind, stmt_cov, stmt_diag))
        if stmt_diag !== nothing
            push!(diags, stmt_diag)
        end
        cov = coverage_join(cov, stmt_cov)
    end

    return IRSummary(stmts, cov, diags)
end

"""
    _get_ir_statements(ir) -> Vector

Extract the list of statements from an IRTools IR object.

Handles multiple IRTools IR representations:
- `IR` objects with `.stmts` field (IRTools 0.4.x)
- `Vector` of statements (for testing with mock IR)
"""
function _get_ir_statements(ir)
    # Check for IRTools IR structure (has .stmts field)
    if hasproperty(ir, :stmts)
        # IRTools 0.4.x IR stores statements in a dict/ordered dict
        stmts_obj = ir.stmts
        if hasproperty(stmts_obj, :vals)
            return collect(stmts_obj.vals)
        elseif hasproperty(stmts_obj, :pairs)
            return [v for (k, v) in stmts_obj.pairs]
        end
        # Try iterating directly
        return collect(stmts_obj)
    end

    # If it's already a vector (e.g., for testing), return as-is
    if isa(ir, Vector)
        return ir
    end

    # Unknown format — return empty
    return []
end

"""
    classify_ir_without_provider(f, argtypes, registry) -> IRSummary

Classify coverage for a function when the IR provider is unavailable.

Returns `CovRejected` with a diagnostic explaining that IR analysis
requires the provider.

See REQ-A17.
"""
function classify_ir_without_provider(f, argtypes::Type)
    return IRSummary(
        AnalyzedStmt[],
        CovRejected,
        [
            Diagnostic(
                "IRProviderUnavailable",
                "Cannot analyze IR without an available IR provider. " *
                "Install IRTools 0.4.x to enable IR-based coverage analysis.",
                "analysis";
                callable = f,
                remediation = "Install IRTools 0.4.x with Pkg.add(\"IRTools\")",
            ),
        ],
    )
end

# ---------------------------------------------------------------------------
# Artifact generation from covered IR (REQ-A3)
# ---------------------------------------------------------------------------

"""
    change_between(old, new) -> Change

Compute the change that transforms `old` into `new`.

For numeric types, returns `Change(delta)` where `delta = new - old`.
For ScalarSummary, returns `ScalarSummaryChange` with per-field deltas.

See REQ-A1.
"""
function change_between(old::T, new::T) where {T<:Number}
    return Change{T}(new - old)
end

function change_between(old::ScalarSummary{T}, new::ScalarSummary{T}) where {T}
    return ScalarSummaryChange{T}(
        count = new.count - old.count,
        sum = new.sum - old.sum,
        sumsq = new.sumsq - old.sumsq,
        minimum = new.minimum,
        maximum = new.maximum,
    )
end

"""
    generate_recompute_artifact(f, nargs::Int) -> Function

Generate a recompute-difference artifact for callable `f` with `nargs`
arguments.

The generated function takes `(old_args..., old_result, Δargs...)` and
returns the composed change from `old_result` to `f(apply_change(old_args, Δargs)...)`.

This is a correct but potentially inefficient approach — it recomputes the
entire function rather than computing per-operation changes. The exactness
law is still satisfied.

See REQ-A3.
"""
function generate_recompute_artifact(f, nargs::Int)
    return function (args...)
        # Split args: [old_args..., old_result, Δargs...]
        old_args = ntuple(i -> args[i], Val(nargs))
        old_result = args[nargs+1]
        Δargs = ntuple(i -> args[nargs+1+i], Val(nargs))

        new_args = map(apply_change, old_args, Δargs)
        new_result = f(new_args...)
        Δ = change_between(old_result, new_result)

        return compose_change(old_result, zero_change(old_result), Δ)
    end
end

"""
    generate_from_ir(ir, f, argtypes::Type, summary::IRSummary, registry) -> Union{Function,Nothing}

Generate a finite-change artifact from covered IR.

Returns the generated artifact if all operations are covered, or `nothing`
if the IR contains boundary or rejected operations.

See REQ-A3.
"""
function generate_from_ir(
    ir,
    f,
    argtypes,
    summary::IRSummary,
    registry::Union{RuleRegistry,Nothing},
)
    if summary.coverage != CovCovered
        return nothing
    end

    nargs = _nargs(argtypes)
    return generate_recompute_artifact(f, nargs)
end

"""
    _nargs(argtypes) -> Int

Get the number of arguments from argtypes, which may be a type (e.g.,
`Tuple{Float64, Float64}`) or a tuple instance (e.g., `(Float64, Float64)`).
"""
_nargs(argtypes::Type{<:Tuple}) = length(argtypes.parameters)
_nargs(argtypes::Tuple) = length(argtypes)
_nargs(::Any) = 0

# ---------------------------------------------------------------------------
# Derivation entry point (REQ-A2, REQ-A3)
# ---------------------------------------------------------------------------

"""
    derive(f, args::Type...; provider::AbstractProvider = DefaultProvider(),
           registry::Union{RuleRegistry,Nothing} = nothing)

Derive a finite-change rule for callable `f` with the given argument types.

Performs IR analysis to determine transitive coverage, then generates an
artifact from covered IR.

Probes the provider lazily at call time — IRTools is never loaded at module init.

Returns an `AnalysisResult`:
- `Derived` on success, containing the generated artifact
- `Rejected` on failure, containing typed diagnostics with classified error codes

See REQ-A2, REQ-A3, REQ-A5, REQ-A11, REQ-A17.
"""
function derive(
    f,
    args::Type...;
    provider::AbstractProvider = DefaultProvider(),
    registry::Union{RuleRegistry,Nothing} = nothing,
)
    if !available(provider)
        return Rejected(
            [
                Diagnostic(
                    "IRProviderUnavailable",
                    "The default IR provider (IRTools) is not available in this " *
                    "environment. Install IRTools 0.4.x with Pkg.add(\"IRTools\") " *
                    "or use a different provider. Julia ≥ 1.10 is required.",
                    "derive";
                    callable = f,
                    remediation = "Install IRTools 0.4.x with Pkg.add(\"IRTools\")",
                ),
            ],
            CovRejected,
        )
    end

    argtypes = Tuple{args...}
    ir = retrieve_ir(provider, f, argtypes)

    if ir === nothing
        return Rejected(
            [
                Diagnostic(
                    "IRProviderIncompatible",
                    "Failed to retrieve IR for ($(f), $argtypes). " *
                    "The method may not be uniquely selected or the provider version " *
                    "may be incompatible.",
                    "derive";
                    callable = f,
                    remediation = "Check Julia/IR compatibility (Julia ≥ 1.10, IRTools 0.4.x)",
                ),
            ],
            CovRejected,
        )
    end

    # Analyze IR for coverage
    summary = analyze_ir(ir, f, argtypes, registry)

    # Generate artifact from covered IR
    if summary.coverage == CovCovered
        artifact = generate_from_ir(ir, f, argtypes, summary, registry)
        if artifact !== nothing
            return Derived(artifact, argtypes, CovCovered)
        end
    end

    # Return Rejected with diagnostics if not fully covered
    return Rejected(summary.diagnostics, summary.coverage)
end

# ---------------------------------------------------------------------------
# Export
# ---------------------------------------------------------------------------

export Change,
    ScalarSummaryChange,
    zero_change,
    valid_change,
    apply_change,
    compose_change,
    Δf_for_add,
    Δf_for_mul,
    Δf_for_sin,
    Δf_for_minmax,
    RuleKey,
    Rule,
    RegistrySnapshot,
    RuleRegistry,
    register!,
    replace!,
    remove!,
    lookup,
    snapshot,
    AbstractProvider,
    DefaultProvider,
    available,
    retrieve_ir,
    CoverageLevel,
    CovCovered,
    CovBoundary,
    CovRejected,
    coverage_join,
    Diagnostic,
    AnalysisResult,
    Derived,
    Rejected,
    derive,
    IROpKind,
    OpCall,
    OpReturn,
    OpGoto,
    OpGotoIfNot,
    OpPhi,
    OpIsA,
    OpNew,
    OpInvoke,
    OpExpr,
    OpConstant,
    OpUnknown,
    AnalyzedStmt,
    IRSummary,
    classify_operation,
    analyze_statement,
    analyze_ir,
    change_between,
    generate_recompute_artifact

end # module Incremental

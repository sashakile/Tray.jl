# ── Tray.jl – common tasks ──────────────────────────────────────────────────
project  := "Tray"
julia    := "julia"

# ── Test ────────────────────────────────────────────────────────────────────

# Run all tests
test:
    {{ julia }} -e 'using Pkg; Pkg.test()'

# Run tests with verbose output
test-verbose:
    {{ julia }} -e 'using Pkg; Pkg.test(; test_args=["verbose"])'

# Run a specific test file
test-file f:
    {{ julia }} --project=. -e 'using ReTestItems; retest("{{ f }}")'

# ── Format ──────────────────────────────────────────────────────────────────

# Format all Julia files (uses JuliaFormatter)
fmt:
    {{ julia }} -e '
    using JuliaFormatter
    format(".")
    '

# Check formatting without modifying
fmt-check:
    {{ julia }} -e '
    using JuliaFormatter
    format(".", verbose=true, check=true)
    '

# ── Lint ────────────────────────────────────────────────────────────────────

# Spell-check with typos
spell-check:
    typos .

# Prose lint with vale
vale:
    vale --glob='*.md' .

# ── Code Quality ────────────────────────────────────────────────────────────

# Run pretender checks
pretender-check:
    pretender check .

# Run mutation tests
mutation:
    pretender mutation

# Run test select with testaruda
test-select:
    testaruda select .

# ── Coverage ────────────────────────────────────────────────────────────────

# Run tests with coverage
coverage:
    {{ julia }} -e '
    using Pkg
    ENV["JULIA_COVERAGE"] = "user"
    Pkg.test(; coverage=true)
    '

# ── Docs ────────────────────────────────────────────────────────────────────

# Build docs (Documenter.jl)
doc:
    cd docs && {{ julia }} --project=. -e "using Pkg; Pkg.instantiate()" && {{ julia }} --project=docs -e 'include("make.jl")' && echo "Docs built to docs/build/"

# ── Clean ───────────────────────────────────────────────────────────────────

# Clean generated files
clean:
    rm -rf docs/build docs/site
    rm -f *.jl.cov *.jl.*.cov *.jl.mem

# ── CI-like full check ──────────────────────────────────────────────────────

# Run the full CI pipeline locally
ci: fmt-check test spell-check

# ── Project Status ──────────────────────────────────────────────────────────

# Show project status
status:
    @printf '\033[1m=== %s ===\033[0m\n' "{{ project }}"
    @printf '  Julia:   '; {{ julia }} --version
    @printf '  Tests:   '; ls -d test/
    @printf '  Spec:    '; ls risk-tree-ears-spec.md 2>/dev/null; ls specs/ 2>/dev/null
    @printf '  Beads:   '; bd list 2>/dev/null | wc -l; printf " issues"

# ── Help ────────────────────────────────────────────────────────────────────

_default:
    @just --list

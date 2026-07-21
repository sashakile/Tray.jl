# ── Tray.jl – common tasks ──────────────────────────────────────────────────
project  := "Tray"
julia    := "julia"

# ── Test ────────────────────────────────────────────────────────────────────

# Run all tests
test:
    {{ julia }} --project=. -e 'using Pkg; Pkg.test()'

# Run tests with verbose output
test-verbose:
    {{ julia }} --project=. -e 'using Pkg; Pkg.test(; test_args=["verbose"])'

# Run a specific test file
test-file f:
    {{ julia }} --project=. -e 'using ReTestItems; retest("{{ f }}")'

# ── Format ──────────────────────────────────────────────────────────────────

# Format all Julia files (uses JuliaFormatter)
fmt:
    {{ julia }} --project=. -e 'using JuliaFormatter; all(format(path) for path in ("src", "test", "docs/make.jl")) || exit(1)'

# Check formatting without modifying
fmt-check:
    {{ julia }} --project=. -e 'using JuliaFormatter; all(format(path; verbose=true, check=true) for path in ("src", "test", "docs/make.jl")) || exit(1)'

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
    {{ julia }} --project=. -e 'using Pkg; ENV["JULIA_COVERAGE"] = "user"; Pkg.test(; coverage=true)'

# ── Docs ────────────────────────────────────────────────────────────────────

# Build docs (Documenter.jl)
doc:
    {{ julia }} --project=docs -e 'using Pkg; Pkg.develop(Pkg.PackageSpec(path=pwd())); Pkg.instantiate()'
    {{ julia }} --project=docs docs/make.jl
    @echo "Docs built to docs/build/"

# Check docs build succeeds (no output)
doc-check:
    {{ julia }} --project=docs -e 'using Pkg; Pkg.develop(Pkg.PackageSpec(path=pwd())); Pkg.instantiate()'
    {{ julia }} --project=docs docs/make.jl

# ── Clean ───────────────────────────────────────────────────────────────────

# Clean generated files
clean:
    rm -rf docs/build docs/site
    rm -f *.jl.cov *.jl.*.cov *.jl.mem

# ── CI-like full check ──────────────────────────────────────────────────────

# Run the full CI pipeline locally
ci: fmt-check test spell-check doc-check

# ── Project Status ──────────────────────────────────────────────────────────

# Show project status
status:
    @printf '\033[1m=== %s ===\033[0m\n' "{{ project }}"
    @printf '  Julia:   '; {{ julia }} --version
    @printf '  Tests:   '; ls -d test/
    @printf '  Spec:    '; printf 'tray-jl-ears-spec.md, openspec/changes/\n'
    @printf '  Beads:   '; bd list 2>/dev/null | wc -l; printf " issues"

# ── Help ────────────────────────────────────────────────────────────────────

_default:
    @just --list

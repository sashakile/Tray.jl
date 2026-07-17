# Tray.jl — Project Reflection

## Overview
A Julia library (module `RiskTree`) for hierarchical portfolio risk aggregation.
EARS spec at `risk-tree-ears-spec.md` (44 requirements, REQ-1..44).

## Key Design Decisions
1. **Two-tier statistics**: Monoidal (mergeable) vs non-monoidal (derived from scenario vectors)
2. **Independent groupby axes**: Separate trees per hierarchy, no materialized cross-product
3. **Payload polymorphism**: AbstractPayload with combine/identity interface
4. **O(log_b n) updates**: Path-to-root recomputation on leaf changes
5. **Sketch compression**: Optional t-digest for large nodes (approximate VaR)

## Tooling Stack
- **Build/test**: Julia 1.12, ReTestItems, JuliaFormatter
- **Quality**: pretender (complexity/duplication/mutation)
- **Verification**: dont (epistemic claims), espectacular (spec checking)
- **Test selection**: testaruda (provenance-semiring analysis)
- **Specs**: openspec (spec-driven development)
- **Issues**: beads (prefix TRAYS)
- **Tasks**: just (task runner), prek (pre-commit hooks)

## Conventions
- 4-space indent, JuliaFormatter defaults
- TDD: test-first with ReTestItems
- Tidy First: small, focused commits
- Spec-driven: every feature starts as an OpenSpec proposal
- Ubiquitous language in `.wai/resources/ubiquitous-language/`

## Common Tasks
- `just test` — run test suite
- `just fmt` — format code
- `just ci` — full CI pipeline locally
- `just test-file path` — run specific test file
- `bd new "description"` — create issue
- `openspec change create <id>` — start a change proposal

## Sesitive Commands That Need Care
- `openspec archive <id> --yes` — permanently archives a change
- `pretender check .` — code quality check (advisory unless gating)

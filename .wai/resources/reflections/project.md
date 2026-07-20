# Tray.jl — Project Reflection

## Overview
A scaffold Julia library (module `Tray`) proposed as an authoritative ordered
leaf array with a balanced aggregation index. The root
[`tray-jl-ears-spec.md`](../../../tray-jl-ears-spec.md) is authoritative.

## Key Design Decisions
1. **Tree + array**: Authoritative ordered leaf storage plus a derived balanced index
2. **Two-tier summaries**: Mergeable payloads and statistics derived from aligned samples
3. **Independent axes**: Separate indices per hierarchy, no materialized cross-product
4. **Payload polymorphism**: Operation-based `combine` and schema identity over arbitrary types
5. **O(log_b n) updates**: Path-to-root recomputation on leaf changes
6. **Sketch compression**: Optional aligned-sum sketches with explicit uncertainty
7. **Optional adapters**: Domain interpretations such as financial risk do not define the core

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

## Sensitive Commands That Need Care
- `openspec archive <id> --yes` — permanently archives a change
- `pretender check .` — code quality check (advisory unless gating)

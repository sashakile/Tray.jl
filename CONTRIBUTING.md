# Contributing to Tray.jl

Thank you for considering contributing to Tray.jl!

## Getting Started

```bash
# Clone the repo
git clone https://github.com/sashakile/Tray.jl
cd Tray.jl

# Run tests
just test

# Format code
just fmt
```

## Development Workflow

1. **Create an issue** in beads for tracking: `bd new "your feature"`
2. **Create an OpenSpec proposal**: `openspec change create <change-id>`
3. **Implement** following TDD (test-first) and Tidy First principles
4. **Run CI locally**: `just ci`
5. **Submit a PR**

## Code Quality Gates

Before committing, run:

```bash
just fmt-check    # JuliaFormatter — check formatting
just spell-check  # typos — catch spelling errors
just test         # ReTestItems — run test suite
```

## Project Conventions

- **Julia module**: `RiskTree`
- **Julia version**: 1.12+
- **Testing framework**: ReTestItems
- **Code style**: 4-space indent, JuliaFormatter defaults
- **Specification-driven**: Feature changes start as OpenSpec proposals
- **Issue tracking**: beads (prefix `TRAYS`)

## Spec-Driven Development

This project uses OpenSpec for spec-driven development. All changes must:

1. Start with an OpenSpec change proposal
2. Reference spec requirements by ID (`REQ-N`)
3. Pass `openspec validate --strict` before merging

## Questions?

Open a beads issue or start a discussion on GitHub.

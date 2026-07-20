# Project Context

## Purpose
Tray is a Julia library proposal for an authoritative ordered leaf array paired
with a balanced aggregation index. The current implementation is scaffold-only;
active changes describe proposed behavior rather than deployed capabilities.

## Tech Stack
- Julia 1.12+
- ReTestItems and Test
- Documenter.jl
- OpenSpec and EARS requirements

## Project Conventions

### Code Style
Use JuliaFormatter defaults and four-space indentation. Keep the package and
module name `Tray`; preserve the package UUID across renames.

### Architecture Patterns
Proposed core behavior is domain-neutral and operation-based over arbitrary
payload types. The ordered leaf array is authoritative; the balanced tree is a
derived aggregation index. Optional domain adapters, including financial risk,
must not define core semantics.

### Testing Strategy
Use focused `@testitem` blocks, property/law tests for payload and tree algebra,
full-recomputation oracles for incremental paths, and requirement-to-test
traceability. Specifications must pass strict OpenSpec validation.

### Git Workflow
Keep changes scoped and reviewable. Use the repository's Beads, wai, Rule of 5,
and quality-gate workflows described by the root agent instructions.

## Domain Context
Core examples include telemetry, time series, image tiles, spatial data, and
categorical summaries. Financial terminology belongs only to the optional
`financial-risk` capability.

## Important Constraints
- Preserve stable EARS IDs REQ-1–REQ-44 and REQ-A1–REQ-A17.
- Use FIN-* IDs exclusively for optional financial interpretation.
- Distinguish stable leaf IDs from mutable array ranks.
- Present unimplemented OpenSpec behavior as proposed, never deployed.

## External Dependencies
IRTools is proposed as an optional derive-time provider for compiler-IR
incrementalization. Core module loading and canonical aggregation must not
depend on it.

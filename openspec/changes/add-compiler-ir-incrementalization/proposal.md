# Change: Add Compiler-IR-Based Incremental Update Optimization

## Why
Custom payload authors need a safe way to optimize updates without replacing the lawful, canonical `combine`. This change derives exact finite-change update functions from Julia IR when possible and otherwise falls back to canonical recomputation.

## What Changes
- Define a per-type finite-change algebra and exactness law for generated `Δf` functions (REQ-A1–A3).
- Add an immutable, revisioned rule registry and a sealed analysis result with transitive coverage (REQ-A4–A5).
- Validate exact primitive rules and all three core payload baselines (REQ-A6).
- Route optional generated updates through one strategy adapter while retaining `combine` and a full-recompute oracle (REQ-A7, REQ-A9).
- Bound v1 to pure straight-line and branch-stable code; classify every unsupported boundary and failure (REQ-A8, REQ-A10–A11).
- Bind artifacts to compilation, closure, registry, and payload-schema identity and publish path updates atomically (REQ-A9, REQ-A16).
- Use an internal IR-provider interface with optional IRTools default on the tested Julia/IRTools matrix (REQ-A2, REQ-A11, REQ-A17).
- Keep LLVM passes, differential-dataflow bindings, and memoization coupling out of scope (REQ-A12–A14); support covered broadcast lowering (REQ-A15).

## Impact
- **New capability**: `compiler-ir-incrementalization`.
- **Affected specs**: New capability only; REQ-A1 through REQ-A17 are preserved and consistently scoped.
- **Affected code**: optional `Tray.Incremental` provider, registry, analysis, artifact, and update-strategy internals.
- **Affected tests**: algebra laws, rules, provider matrix, artifact invalidation, analysis coverage, three payload baselines, and atomic update fallback.

## Dependencies
- The core payload types, lawful `combine` operations, and ancestor-path update infrastructure remain authoritative.
- IRTools is optional and required only by the default derivation provider; registry operations and already-generated artifacts remain usable without it.

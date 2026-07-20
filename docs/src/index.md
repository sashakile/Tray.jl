# Tray.jl

Tray is an ordered leaf array with a balanced aggregation index in Julia.

The current `Tray` implementation is a scaffold only. The behavior described in
the specifications is proposed and has not yet been implemented.

## Key Concepts

- **Ordered leaves** — values retain a stable array order
- **Balanced aggregation index** — proposed internal nodes summarize leaf ranges
- **Domain-neutral core** — aggregation is independent of application domain

## Quick Links

- [EARS Specification](generated/tray-jl-ears-spec.md) — full requirements (REQ-1..44)
- [OpenSpec Changes](specs/index.md) — active change proposals
- [Implementation Status](status.md) — what's built and what's planned

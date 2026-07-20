# Testing Strategy

## Framework

- **ReTestItems** for test item-based testing
- **Test** stdlib for assertions

## Test Organization

Tests are in `test/runtests.jl` organized by `@testitem` blocks.

## Coverage

Coverage is tracked via `julia-actions/julia-processcoverage` in CI and
uploaded to Codecov with a 50% project gate and an 80% patch target.

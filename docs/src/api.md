---
title: API Reference
description: Auto-generated API reference for the Tray module — exported types, functions, and macros.
category: Reference
---

# API Reference

> **Note:** This page is populated by Documenter.jl's `@autodocs` block during the HTML build.
> The raw markdown shows only the directive below. For a quick offline reference, see
> `llm.txt` (repo root) or the [Examples page](examples.md).

## Exported Names Overview

The `Tray` module exports the following public API surface:

**Core types:** `Tree`, `ScalarSummary`, `ScalarSchema`, `AttributionPayload`, `AttributionSchema`,
`SamplePayload`, `AlignedArrayPayload`, `SnapshotEpoch`, `DashboardModel`

**Key functions:** `combine`, `identity`, `range_query`, `update`, `update!`, `insert!`, `remove!`,
`reweight_subtree`, `save_tree`, `load_tree`, `derived_mean`, `derived_variance`, `derived_std`,
`derive_ratio`, `project_samples`, `moment_quantile`, `quadratic_projection`,
`normalized_covariance_contribution`

**Module aliases:** `TrayBase` (core algebra), `Tray.Incremental` (optional IR incrementalization)

---

```@autodocs
Modules = [Tray]
Private = false
Order   = [:module, :type, :function]
```

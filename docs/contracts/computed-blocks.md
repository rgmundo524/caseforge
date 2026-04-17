# Computed Blocks Contract

> Status: draft contract

## Purpose

Canonical report files need to reference computed content such as:
- metrics
- tables
- figures

This document defines the planned renderer-aware but analysis-safe direction for those references.

## Why this exists

The project wants:
- canonical analysis truth in shared DuckDB/SQL outputs
- canonical report truth in Quarto-authored report files
- an analysis UI in Evidence

A computed block system is the bridge between those layers.

## Planned direction

Canonical report files reference named computed blocks via CaseForge directives.

Illustrative examples:

```md
:::cf.metric
block_id: theft_transaction_count
:::
```

```md
:::cf.table
block_id: theft_transactions_summary
:::
```

```md
:::cf.figure
block_id: cross_chain_pairs_overview
caption: Cross-chain movement of traced funds.
:::
```

## Planned architecture

- canonical analysis outputs register block ids
- report files reference those block ids
- Quarto report outputs map them into report-rendered content
- Evidence may later map some of the same blocks into analysis-site widgets

## Constraint

This contract exists to avoid:
- duplicating heavy analysis logic across many `.qmd` files
- forcing canonical report files to become a tangle of renderer-specific ad hoc code

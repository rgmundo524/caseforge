# Computed Blocks Contract

> Status: draft contract

## Purpose

Canonical narrative sections will need to reference computed content such as:
- metrics
- tables
- figures

This document defines the planned renderer-neutral direction for those references.

## Why this exists

The project wants full Evidence capabilities in WEB while still keeping PDF feasible later.

Making canonical sections Evidence-native would make WEB easier short-term but create a difficult WEB-to-PDF compatibility problem.

## Planned direction

Canonical markdown references named computed blocks via CaseForge directives.

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

- features and core analysis register block ids
- WEB renderer maps them to Evidence-native output
- PDF renderer later maps them to PDF-compatible output

## Constraint

This is a later milestone. The directive grammar and block registry should be designed before PDF implementation, but after feature lifecycle and narrative composition contracts are stabilized.

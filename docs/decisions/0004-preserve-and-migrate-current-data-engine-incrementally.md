# ADR 0004: Preserve the current data engine and migrate it into the workspace model incrementally

- Status: Accepted
- Date: 2026-04-11

## Context

The current CaseForge repository already contains working and valuable capabilities:
- template layering
- raw evidence registration
- normalization into DuckDB
- downstream analytical view construction
- Evidence source extraction

A redesign of the product should not discard those capabilities without necessity.

## Decision

The redesign will preserve the existing data/analysis engine where possible and migrate it into the new workspace model incrementally.

This means:
- the current ingestion and DuckDB build logic remains a core subsystem
- redesign work should first wrap and relocate existing capabilities before replacing them
- the first redesign milestone should prove a vertical slice rather than attempt a full rewrite

## Consequences

### Positive
- lowers rewrite risk
- preserves already-working analytical logic
- allows incremental progress
- makes the redesign easier to test against known sample cases

### Tradeoffs
- some temporary duplication or adapter code may be necessary
- old assumptions may persist briefly while the new model takes shape

## Follow-on Implications

This decision supports:
- a long-lived redesign branch
- phased migration
- early workspace/API scaffolding without immediate replacement of all existing commands

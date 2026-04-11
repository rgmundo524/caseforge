# ADR 0001: CaseForge becomes a persistent case workspace system

- Status: Accepted
- Date: 2026-04-11

## Context

The current CaseForge architecture is centered on generating a standalone Evidence project per case.

That model has been useful for proving:
- case scaffolding
- template layering
- SQL-first normalization
- Evidence-oriented analytical output

However, the actual investigation lifecycle is longer and richer than a single project-generation session.

Investigators need:
- persistent case workspaces
- human-authored narrative sections
- repeatable regeneration over time
- multiple output targets
- a system that begins the investigation and remains the home of the case until final output

## Decision

CaseForge is redefined as a **persistent case workspace system**.

This means:
- a case is no longer modeled primarily as an Evidence project
- a case is modeled as a long-lived workspace
- CaseForge owns workspace creation, ongoing state, data ingestion, authored content scaffolding, and output generation
- web and PDF outputs become render targets rather than the sole identity of the case

## Consequences

### Positive
- supports the real investigation lifecycle
- makes room for investigator-authored narrative content
- supports multiple outputs from shared sources
- keeps the existing data engine valuable within a broader architecture
- provides a clear home for persistence and regeneration

### Tradeoffs
- requires a significant refactor of project structure
- increases the importance of explicit workspace metadata/state
- requires clearer separation between source content and generated output
- makes a purely CLI-only worldview insufficient

## Follow-on Implications

This decision implies:
- a case workspace directory model
- canonical authored section files
- a shared structured source layer
- renderer adapters for web and PDF outputs
- API-first orchestration over time

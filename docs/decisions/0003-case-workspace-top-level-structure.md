# ADR 0003: The case workspace is organized around Sections, Sources, WEB, and PDF

- Status: Accepted
- Date: 2026-04-11

## Context

The previous architecture treated the generated Evidence project as the effective case structure.

The redesign needs a stable top-level workspace shape that:
- gives investigators a clear home for authored content
- gives the data engine a clear home for evidence and analytical artifacts
- allows multiple output targets
- avoids making any single renderer the definition of the case

## Decision

Each case workspace will be organized around four primary top-level directories:

- `Sections/`
- `Sources/`
- `WEB/`
- `PDF/`

### `Sections/`
Canonical investigator-authored markdown source content.

### `Sources/`
Canonical structured substrate for raw evidence, DuckDB, manifests, snapshots, and analytical artifacts.

### `WEB/`
Generated web render targets and renderer-specific assets.

### `PDF/`
Generated PDF/LaTeX render targets and renderer-specific assets.

## Consequences

### Positive
- makes the role of each area explicit
- supports both human-authored and machine-generated materials
- creates a stable base for multiple renderers
- allows Evidence and LaTeX to coexist without either becoming the whole system

### Tradeoffs
- introduces a broader workspace model than the current project
- requires migration of current Evidence-centered assumptions
- requires a clear contract between source content and renderers

## Notes

This decision does not yet lock in:
- exact subdirectory layout within each area
- exact section metadata schema
- exact renderer registration model

Those remain follow-on design tasks.

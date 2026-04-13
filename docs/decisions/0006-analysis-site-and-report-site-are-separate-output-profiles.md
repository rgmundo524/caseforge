# ADR 0006: Analysis site and report site are separate output profiles

- Status: Accepted
- Date: 2026-04-12

## Context

A live investigation needs an analysis output during the case, while a report output depends on investigator-authored narrative content.

Treating these as one output caused a bad coupling: feature analysis risked being hidden until corresponding narrative markdown existed.

## Decision

CaseForge will distinguish at least two WEB output profiles:

- `analysis_site`
- `report_site`

### `analysis_site`
Generated from:
- standard analysis
- enabled feature analysis
- current shared data in `Sources/`

It does not depend on narrative section files existing.

### `report_site`
Generated from:
- canonical authored section content in `Sections/`
- selected generated analysis content
- the same shared data in `Sources/`

## Consequences

- features can meaningfully contribute to live investigation outputs without waiting on authored prose
- report-style composition can evolve independently from analysis-site generation
- output profiles must become an explicit config concept

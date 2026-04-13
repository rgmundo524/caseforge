# CaseForge Investigative Guide

> Status: draft outline
>
> This guide is intentionally incomplete. It exists to document the intended investigative workflow as the project evolves.

## 1. Purpose

CaseForge is designed to support live investigations that evolve over time.

The system should help investigators:
- ingest and refresh raw exports repeatedly
- preserve a structured case workspace
- generate live analysis outputs during the investigation
- author narrative/report content without losing analytical reproducibility
- later produce report-style and PDF outputs from the same case

CaseForge is not intended to fully automate investigation judgment.

## 2. Investigation lifecycle

Current working lifecycle:

1. create workspace
2. add or refresh raw exports
3. normalize
4. build database
5. build analysis site
6. author or revise narrative sections
7. build report site
8. snapshot/finalize when needed

This cycle is expected to repeat many times during an active investigation.

## 3. Workspace structure

### `Sections/`
Canonical investigator-authored narrative content.

### `Sources/`
Canonical structured data/build substrate.

### `WEB/`
Generated Evidence outputs.

### `PDF/`
Future generated PDF outputs.

### `.caseforge/`
Workspace metadata and configuration.

## 4. Features

Features are dynamic and config-driven for build/runtime behavior.

A feature may contribute:
- analysis SQL/views
- source queries
- generated WEB pages
- reusable computed blocks

Features selected at `init-workspace` may also seed investigator-facing section scaffolds to provide a stronger starting structure.

Later edits to feature config change builds and generated outputs, but should not automatically restructure the investigator's section tree.

## 5. Output profiles

### `analysis_site`
Generated from:
- standard analysis
- enabled feature analysis
- current DuckDB state

It should not depend on the existence of narrative section files.

### `report_site`
Generated from:
- canonical section tree in `Sections/`
- selected generated analysis content
- current shared case data

### `pdf_report`
Future PDF output consuming the same canonical section tree and computed block system.

## 6. Writing investigator sections

Planned model:
- filesystem-first structure
- `index.md` for page-level content
- sibling markdown files for ordered blocks
- frontmatter as override
- future support for limited Obsidian-friendly syntax

## 7. Computed blocks

Planned future direction:
- `cf.metric`
- `cf.table`
- `cf.figure`

These should be renderer-neutral references to computed content, not raw renderer-specific code in canonical markdown.

## 8. OSINT and cyber investigation

Planned feature families should eventually support:
- identifiers and aliases
- domains and websites
- social/account correlations
- infrastructure indicators
- cross-domain correlation with on-chain analysis

## 9. Provenance, confidence, and review

Future outputs should support:
- provenance
- confidence
- reviewability
- snapshot/finalization semantics

## 10. Troubleshooting

Future topics:
- build order
- feature config issues
- missing output artifacts
- runtime/bootstrap failures

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
Workspace metadata and future configuration.

## 4. Features

Features should be dynamic and config-driven.

A feature may contribute:
- analysis SQL/views
- source queries
- generated WEB pages
- section prompts/seeds
- reusable computed blocks

Features should save time and expose capabilities. They should not be the only way investigators can structure a case.

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
Future PDF output consuming the same canonical section tree and computed blocks.

## 6. Writing investigator sections

Target model:
- file tree communicates page hierarchy
- `index.md` defines page lead/body
- sibling markdown files define ordered page blocks
- frontmatter refines title, order, outputs, and optional overrides

## 7. Computed blocks

Planned model:
- canonical markdown references computed objects via CaseForge directives
- WEB and PDF each render those directives differently

Examples to support later:
- metrics
- tables
- figures

## 8. OSINT and cyber investigation

The system should explicitly support feature families beyond blockchain-only analysis.

Planned areas:
- identifier OSINT (email, phone, username, alias, domain)
- cyber/infrastructure (IP, DNS, hosting, headers, TLS, phishing infra)
- cross-domain correlation between on-chain, OSINT, and cyber evidence

## 9. Provenance and confidence

The system should preserve:
- source provenance
- feature origin of generated content
- confidence/context notes where relevant
- reproducibility of analytical outputs

## 10. Snapshot and finalization

The system should later support snapshot points in time so the state of a case can be preserved for:
- counsel review
- report filing
- disclosure packages
- later regeneration of outputs

## 11. Troubleshooting notes

Current practical reminders:
- follow the build order: `add-files -> normalize -> build-db -> build-web-draft`
- use fresh workspaces for major smoke validation when checking architecture changes
- treat `WEB/` as generated output, not the canonical authoring surface

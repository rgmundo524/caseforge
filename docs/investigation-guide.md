# CaseForge Investigative Guide

> Status: draft workflow guide
>
> This guide documents the intended investigation workflow under the Quarto-centered report architecture.

## 1. Purpose

CaseForge supports live investigations that evolve over time.

The system should help investigators:
- ingest and refresh raw exports repeatedly
- preserve a structured local case workspace
- generate a live analysis UI during the investigation
- author report content without losing analytical reproducibility
- render report outputs in HTML/PDF from the same case state
- capture explicit snapshot points when needed

CaseForge is not intended to fully automate investigator judgment.

## 2. Operating model

CaseForge is designed as a **local-first** investigation application.

The default expectation is:
- the investigator has a local copy of the case workspace
- canonical data builds happen locally
- the analysis site runs locally
- report outputs render locally
- sync/backup/collaboration are optional and secondary

## 3. Case lifecycle

### Phase 1 — Create or open case
The investigator creates a workspace and chooses the starting template/features.

At this point CaseForge should:
- scaffold the workspace
- seed report section scaffolds for selected init-time features
- write feature/output config

### Phase 2 — Add or refresh evidence
As the investigation evolves, the investigator periodically:
- adds or replaces raw exports
- runs normalize
- runs build-db

This should be routine and repeatable.

### Phase 3 — Review live analysis
The investigator builds or refreshes the analysis site.

The analysis site should always reflect:
- current canonical data
- current enabled analysis features
- current canonical marts/views

The analysis site should not depend on report authoring being finished.

### Phase 4 — Author the report
The investigator edits the report tree under `Sections/`.

The report tree should be the canonical report authoring surface and should move toward `.qmd` as the default rendered report format.

### Phase 5 — Render report outputs
CaseForge prepares the report model/project for Quarto.

Quarto then renders:
- report HTML
- PDF report
- later profile-specific variants

### Phase 6 — Snapshot and finalize
At important points, the investigator snapshots:
- feature state
- report tree state
- canonical data build state
- rendered outputs

This is how the system preserves reproducible reporting at a point in time.

## 4. Workspace structure

### `Sections/`
Canonical report authoring tree.

### `Sources/`
Canonical structured data/build substrate.

### `WEB/`
Generated analysis-site outputs (currently Evidence).

### `PDF/`
Legacy placeholder; formal report outputs should increasingly be viewed as Quarto-driven rather than bespoke PDF workspace outputs.

### `.caseforge/`
Workspace metadata, feature config, and output-profile state.

## 5. Features

Features are dynamic and config-driven for build/runtime behavior.

A feature may contribute:
- canonical analysis marts/views
- analysis-site pages/queries
- report section seeds
- report blocks
- future Quarto partials/templates

Features selected at `init-workspace` may seed the initial report tree.

Later edits to feature config change builds and generated outputs, but should not automatically restructure the investigator’s authored report tree.

## 6. Output profiles

### `analysis_site`
Generated from:
- standard analysis
- enabled feature analysis
- current canonical data

Should not depend on authored report files.

### `report_site`
Generated from:
- the report tree in `Sections/`
- selected report blocks
- current canonical data
- Quarto project/profile configuration

### `pdf_report`
Generated from the same report tree and report blocks, using Quarto PDF or Typst-backed Quarto output.

## 7. Report authoring

Current target model:
- filesystem-first report tree
- `.qmd` as the default rendered report format
- `index.qmd` for page-level metadata and lead/body
- sibling files for ordered blocks on a page
- subfolders for child pages

Plain markdown remains appropriate for freeform notes/reference material outside the canonical report tree.

## 8. Computed content

Planned future direction:
- `cf.metric`
- `cf.table`
- `cf.figure`

These should reference prepared canonical datasets/blocks rather than force investigators to duplicate analysis logic in report files.

## 9. OSINT and cyber investigation

Planned feature families should eventually support:
- identifiers and aliases
- domains and websites
- social/account correlations
- infrastructure indicators
- cross-domain correlation with on-chain analysis

## 10. Provenance, confidence, and review

Future outputs should support:
- provenance
- confidence
- reviewability
- snapshot/finalization semantics

## 11. Troubleshooting

Future topics:
- build order
- feature config issues
- Quarto profile/render issues
- analysis-site/runtime issues
- snapshot reproducibility issues

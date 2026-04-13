# CaseForge Architecture

## Overview

CaseForge is evolving from a generator of standalone Evidence case sites into a persistent investigation workspace system.

The architecture now separates:

- canonical narrative authorship
- canonical structured evidence and analytical data
- generated renderer outputs
- dynamic case capabilities (features)

This separation is what allows one case to produce different outputs at different times without losing reproducibility.

## System thesis

A case is **not**:
- only an Evidence project
- only a PDF project
- only an Obsidian vault

A case **is**:
- a persistent workspace containing authored content, structured data, configuration, and generated outputs

## Top-level workspace model

Each case workspace contains four primary areas:

### `Sections/`
Canonical investigator-authored narrative content.

This is where case-specific prose lives:
- case background
- client narrative
- findings
- conclusions
- limitations
- appendix narrative
- future custom report sections

`Sections/` is the authored truth for narrative/report content.

### `Sources/`
Canonical structured substrate for the case.

This is where the case data engine operates:
- raw exports
- manifests
- `case.duckdb`
- normalized views/tables
- analytical helper views
- derived snapshots such as section snapshots

`Sources/` is the shared data/query layer for all outputs.

### `WEB/`
Generated Evidence outputs.

These are not the primary authoring surface. They are generated artifacts that consume:
- `Sections/`
- `Sources/`
- output profile rules
- feature-contributed pages/sources

At least two WEB output profiles are expected:
- `analysis_site`
- `report_site`

### `PDF/`
Future generated PDF outputs.

These will later consume the same canonical section tree and computed block system as WEB, but through a different renderer.

## Configuration model

The workspace is controlled by config files under `.caseforge/`.

The next major config contract is a YAML feature/output config that will describe:
- active features
- per-feature settings
- output profiles
- validation and lifecycle policies

That config should be the canonical editable state for dynamic feature control. A future UI may edit it, but it should not replace it.

## Feature model

Features are dynamic case capabilities, not one-time immutable choices.

A feature may contribute:
- SQL/views
- Evidence source queries
- generated WEB pages
- section seeds/prompts
- reusable computed blocks
- future PDF fragments

Features are therefore different from renderers:
- a feature says what a case can do
- an output profile says what a particular generated output should include

## Output profiles

Output profiles are first-class.

### `analysis_site`
The analysis site is generated from:
- standard analysis
- enabled feature analysis
- DuckDB-backed data and source queries

It should **not** depend on whether the investigator has authored matching narrative sections.

### `report_site`
The report site is generated from:
- the investigator-authored section tree
- selected generated analysis content
- the same shared case data in `Sources/`

### `pdf_report`
The future PDF report should consume the same canonical section tree and computed block system as the report site.

## Composition model

### Narrative composition
Narrative/report outputs should use a filesystem-first composition model:
- folder path defines page hierarchy
- `index.md` defines the page lead/body
- sibling markdown files define ordered blocks on that page
- subfolders define child pages
- frontmatter refines the structure

This gives investigators simple control via the file tree instead of requiring template edits for every new section.

### Analysis composition
Analysis outputs are generated from:
- standard pages
- feature-contributed pages
- feature-contributed source queries
- shared data in `Sources/`

They are not blocked by missing narrative sections.

## Computed content model

Canonical section files should remain renderer-neutral.

To support figures, tables, metrics, and similar computed objects, CaseForge will use a shared directive system in canonical markdown rather than raw Evidence-native syntax.

Examples (future contract):
- `cf.metric`
- `cf.table`
- `cf.figure`

Those directives will resolve through a shared block registry and then render differently for WEB and PDF.

This avoids turning canonical sections into Evidence-native documents and keeps PDF feasible.

## WEB bootstrap model

WEB output should reuse the same standalone Evidence bootstrap seam already used by the legacy standalone case generation path.

CaseForge should **not** maintain a separate mini Evidence runtime inside the repository.

The correct boundary is:
- Evidence bootstrap creates a runnable runtime root
- CaseForge owns `pages/` and `sources/` content after bootstrap
- `evidence.config.yaml` and datasource linkage are then updated to point at shared case data in `Sources/`

## Ownership boundary in WEB outputs

### Bootstrap-owned runtime files
Examples:
- `package.json`
- `package-lock.json`
- `.npmrc`
- `degit.json`
- runtime scripts

### CaseForge-owned generated content
Examples:
- `pages/`
- `sources/`
- `.caseforge/web_output.json`
- generated narrative/report pages
- generated source connections pointing back to `Sources/data/case.duckdb`

## Investigation lifecycle

A live case is expected to rebuild often.

Typical cycle:
1. create workspace
2. add or replace raw exports
3. normalize
4. build database
5. update sections if needed
6. build analysis site and/or report site
7. repeat while the investigation evolves
8. snapshot/finalize outputs when needed

This means the architecture should optimize for repeated rebuilds and explicit configuration, not a single one-shot generation event.

## Obsidian role

Obsidian remains an authoring environment, not the renderer.

CaseForge should later support a controlled subset of Obsidian-friendly syntax (links and embeds) during snapshot/build, while keeping renderers independent of Obsidian itself.

## Migration principle

The redesign should preserve and reuse existing subsystems where possible:
- raw evidence registration
- normalization/build pipeline
- template layering
- shared standalone Evidence bootstrap seam

The redesign is therefore a reorganization around a stronger case model, not a wholesale discard of the existing engine.

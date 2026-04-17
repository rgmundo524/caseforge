# CaseForge Architecture

## Overview

CaseForge is evolving from a generator of standalone Evidence case sites into a local-first case-analysis application with a canonical report model.

The architecture is now centered on a four-layer split:

1. canonical analysis
2. canonical report model
3. publishing / report rendering
4. interactive analysis UI

This is what allows one case to produce multiple outputs without letting any single renderer become the source of analytical truth.

## System thesis

CaseForge is **not**:
- only an Evidence project
- only a PDF project
- only a Quarto project
- only a vault of notes

CaseForge **is**:
- a persistent workspace for a case
- a canonical data and analysis pipeline
- a canonical report model
- an orchestrator of multiple output systems

## The four-layer model

### Layer A — Canonical analysis layer
Owned by CaseForge and DuckDB.

This layer contains:
- raw evidence registration
- normalization
- attribution
- cross-chain logic
- canonical marts/views
- chart-ready data
- appendix-ready data
- report-ready summary datasets

This is the single source of analytical truth.

### Layer B — Canonical report model
Owned by CaseForge.

This layer contains:
- report authoring tree
- report section metadata
- feature config
- output profile intent
- snapshot metadata
- future computed block references

This is where narrative/report truth lives.

### Layer C — Publishing / report system
Owned by Quarto.

This layer should contain:
- Quarto project config (`_quarto.yml` and profile-specific config)
- report rendering orchestration
- profile-specific report behavior
- HTML and PDF report outputs
- Typst output path when appropriate

Quarto is the canonical report/project system because it already provides:
- project-wide configuration
- profile-based configuration merging
- render orchestration for entire projects
- output directory control
- executable documents
- freeze support for reproducible project renders
- support for multiple output formats, including Typst

### Layer D — Interactive analysis UI
Owned by Evidence for now.

This layer should contain:
- analyst-facing interactive views
- feature-generated analysis pages
- filtering/slicing over canonical analysis outputs
- thin presentational transforms

It should not be the place where canonical analytical truth keeps being invented.

## Workspace model

Each case workspace contains four primary areas plus metadata:

### `Sections/`
Canonical report authoring tree.

This area should evolve toward Quarto-native authored report files (`.qmd`) for rendered report outputs.

It owns:
- report structure
- report sections/blocks
- report-specific narrative truth

It should not be required for the analysis site to exist.

### `Sources/`
Canonical structured substrate for the case.

This area owns:
- raw exports
- manifests
- `case.duckdb`
- normalized views/tables
- canonical marts/views
- derived snapshots

All renderers and report systems should consume prepared truth from here rather than reinventing it.

### `WEB/`
Generated analysis-site outputs.

This is currently the Evidence path.

It should be treated as:
- generated
- disposable/rebuildable
- useful for analysis and review
- not the source of canonical report truth

### `PDF/`
Legacy placeholder for future generated PDF outputs.

Under the new direction, formal report outputs should increasingly be thought of as Quarto outputs rather than a bespoke `PDF/` subsystem.

### `.caseforge/`
Workspace metadata and configuration.

This area owns:
- feature config
- output-profile config/state
- workspace metadata
- snapshot/build state metadata

## Configuration model

The workspace is controlled by config files under `.caseforge/`.

The current canonical feature/output config is YAML-based and is intended to describe:
- active features
- per-feature settings
- output profiles
- validation and lifecycle policies

This config is the canonical editable state for dynamic feature control.

A future UI may edit it, but should not replace it.

## Features

Features are dynamic case capabilities, not one-time immutable choices.

A feature may contribute:
- canonical analysis SQL/views
- analysis-site pages/sources
- report section seeds
- report blocks
- future Quarto partials/templates

### Two kinds of feature effects

#### Build/runtime effects
These are dynamic and come from the current feature config.

Examples:
- enabling/disabling canonical marts/views
- enabling/disabling generated analysis-site pages
- changing which features are reflected in engine metadata
- changing which report blocks are available

These effects may change during the investigation.

#### Authoring scaffold effects
These seed investigator-facing report structure.

The current design rule is:
- features explicitly selected at `init-workspace` may seed report scaffolds under `Sections/`
- later edits to `.caseforge/features.yaml` must **not** automatically add/remove/move investigator-authored report files
- if later we support post-init reseeding, it must be an explicit investigator action

## Output profiles

Output profiles are first-class and are no longer just renderer names.

### `analysis_site`
Generated from:
- standard analysis
- enabled feature analysis
- current canonical marts/views

It should **not** depend on the existence of authored report files.

### `report_site`
Generated from:
- canonical report tree in `Sections/`
- selected report blocks / computed objects
- current shared case data in `Sources/`
- Quarto project/profile configuration

### `pdf_report`
Generated from:
- the same canonical report tree and blocks as `report_site`
- Quarto PDF or Typst-backed Quarto output

## Report authoring model

### Default file format
For rendered report outputs, the default authoring format should move toward `.qmd`, not wrapper-based `.md` files.

Reason:
- Quarto is the canonical report system
- `.qmd` is a first-class Quarto input format
- wrapper-based `.md -> .qmd` conversion adds friction without a strong benefit

Plain `.md` should still remain useful for:
- notes
- scratch material
- reference/supporting material
- internal docs

### Filesystem-first report tree
A report tree should define report hierarchy by path:
- folder = page/chapter/section node
- `index.qmd` = page-level metadata + lead/body
- sibling files = ordered blocks on that page
- subfolders = child pages

This remains the preferred composition model for report outputs.

## Quarto-specific design opportunities

Quarto already provides capabilities that CaseForge should deliberately rely on rather than rebuilding:

- project-wide config via `_quarto.yml`
- directory/document metadata inheritance via `_metadata.yml` and document YAML
- profile-specific config merging
- profile-conditional content via `when-profile`
- project render orchestration
- output directory control
- freeze for reproducible project rendering
- includes for plain markdown and `.qmd`
- dashboards, websites, books, and PDF outputs
- Typst output path

## Guardrails for Quarto

Quarto can legitimately own canonical report truth, but we should not recreate the renderer-coupling problem there.

### Allowed in Quarto
- report structure
- report assembly
- profile-conditional content
- report-local summaries over canonical datasets
- reusable report partials/includes
- report-level orchestration and execution

### Not allowed as the only source of truth
- deep cross-chain logic scattered across many pages
- duplicated attribution logic in many documents
- copy-pasted heavy SQL that defines canonical facts independently of shared marts/views

The rule is:

**Quarto may execute and orchestrate report logic, but heavy analytical truth must remain centralized and inspectable.**

## Includes and path discipline

If the report system uses Quarto includes, we must follow Quarto’s actual semantics:
- include shortcodes are equivalent to copy/paste into the main file
- relative references inside the included file resolve relative to the main file, not the included file
- metadata blocks in included files can cause unexpected behavior

Therefore:
- use project-root-relative paths in included content
- avoid metadata blocks in included partials
- reserve includes for reusable partials, not as a wrapper workaround for the whole report tree

## Evidence bootstrap model

Evidence remains useful, but as the analysis UI path.

The correct boundary is:
- Evidence bootstrap creates a runnable runtime root
- CaseForge owns `pages/` and `sources/` content after bootstrap
- `evidence.config.yaml` and datasource linkage then point back to shared case data in `Sources/`

CaseForge should not maintain a separate mini Evidence runtime inside the repository.

## Local-first workflow

The primary operating model should be local-first.

That means:
- the investigator’s machine holds the authoritative workspace
- builds execute locally
- analysis and report outputs are generated locally
- sync/backup/collaboration are secondary and optional

Possible later sync/archival layers include:
- private Git repositories
- encrypted backup archives
- local network shares
- optional sync providers

But the core design should not depend on any third-party sync service.

## Investigation lifecycle

A live case is expected to rebuild often.

Typical cycle:
1. create/open workspace
2. add or replace raw exports
3. normalize
4. build canonical analysis outputs
5. review analysis site
6. author/update report files
7. render Quarto report outputs
8. snapshot/finalize when needed

This architecture should optimize for repeated local rebuilds and reproducible snapshot points.

## Migration principle

The redesign should preserve and reuse existing subsystems where possible:
- raw evidence registration
- normalization/build pipeline
- current feature config
- current section seeding behavior
- the shared standalone Evidence bootstrap seam

The pivot is therefore not “throw away the branch and start over.” It is:
- keep the validated foundation
- change what sits above the report model
- stop expanding renderer-specific truth in the wrong places

# CaseForge Workspace Architecture

## Overview

CaseForge is evolving from a generator of standalone Evidence projects into a persistent case workspace system.

The new architecture separates:

- human-authored case content
- structured evidence and analytical data
- output renderers

This allows one case to produce multiple outputs while preserving a shared canonical source model.

## Architectural Thesis

A case is **not**:
- only an Evidence project
- only an Obsidian vault
- only a PDF project

A case **is**:
- a persistent workspace containing authored content, structured evidence, and generated outputs

## Top-Level Workspace Model

Each case workspace contains four primary areas:

### `Sections/`
Canonical investigator-authored markdown source content.

Purpose:
- hold narrative and interpretive content that cannot be fully automated
- preserve editable human-authored source material
- act as the semantic source for report sections

Examples:
- case background
- client narrative
- investigative findings
- methodology notes
- limitations
- conclusions
- custom appendix fragments

### `Sources/`
Canonical structured substrate for the case.

Purpose:
- hold raw evidence inputs
- hold case DuckDB and manifests
- hold parsed section snapshots
- hold analytical tables/views
- hold test/debug artifacts
- provide the shared data/query layer for renderers

Examples:
- raw CSV exports
- manifest files
- case DuckDB
- normalized and final views
- reference snapshots
- validation outputs

### `WEB/`
Generated web output workspace(s).

Purpose:
- materialize one or more web render targets
- contain renderer-specific generated files
- avoid acting as the primary authoring source

Examples:
- Evidence-based analysis site
- exchange-notification site
- internal review site

### `PDF/`
Generated PDF output workspace(s).

Purpose:
- materialize one or more PDF/LaTeX render targets
- keep renderer-specific formatting concerns out of canonical source content

Examples:
- full report
- client-facing summary
- appendix-only packet
- service notification letter

## Content Classes

The architecture centers on three content classes.

### 1. Authored source content
Owned by investigators.
Primary home: `Sections/`

Characteristics:
- rich markdown
- semantic sections
- frontmatter metadata
- case-specific nuance
- not expected to be fully automated

### 2. Structured analytical/query data
Owned by CaseForge’s data engine.
Primary home: `Sources/`

Characteristics:
- raw inputs
- normalized tables/views
- analytical views
- reference snapshots
- queryable and reproducible

### 3. Renderer-specific templates/adapters
Owned by output layers.
Primary homes: `WEB/` and `PDF/`

Characteristics:
- presentation logic
- layout/placement rules
- output wrappers
- should consume authored content + structured data
- should not become the canonical authorship surface

## Composition Model

Renderers compose outputs from two primary inputs:

- `Sections/` -> authored content
- `Sources/` -> structured/queryable data

A renderer may also use:
- renderer-specific template files
- shared common fragments
- feature-specific output definitions

But the key rule is:

**Renderers consume canonical inputs. They do not define canonical truth.**

## Case Lifecycle

A case should move through a persistent lifecycle rather than a single command run.

High-level lifecycle:

1. create workspace
2. scaffold sections from templates/features
3. ingest raw evidence into `Sources/`
4. build or refresh case DuckDB
5. snapshot/validate authored sections
6. generate one or more outputs
7. revise sections and regenerate as the case evolves
8. finalize outputs

## State and Persistence

The system should track more than files.

CaseForge should know:
- template/features selected
- which section files exist
- which evidence files are registered
- when the DuckDB was last rebuilt
- whether outputs are stale relative to sections/sources
- which outputs have been generated
- whether investigator-authored content changed since the last build

This implies an explicit case-state model in addition to filesystem layout.

## API and CLI Roles

### FastAPI
Primary orchestration layer.

Responsibilities:
- create/open/list cases
- scaffold sections
- register evidence files
- trigger builds
- expose case state
- support future UI flows

### CLI
Secondary operator/developer tool.

Responsibilities:
- debugging
- automation
- testing
- direct scripting
- parity for selected operations where useful

The CLI remains valuable, but it no longer defines the whole product.

## Obsidian Role

Obsidian is a useful authoring environment for markdown source content.

CaseForge should treat Obsidian-compatible markdown as:
- an authoring surface
- a note-navigation environment
- a source of investigator-edited section content

CaseForge should **not** treat live renderer directories as the only authoring source.

The architecture should preserve the ability to:
- edit case sections in Obsidian
- snapshot those sections into case-local structured artifacts
- render outputs from the snapshots and shared analytical layer

## Migration Principle

The current CaseForge repository already contains valuable working subsystems:
- template layering
- raw evidence registration
- normalization/build pipeline
- Evidence source extraction

The redesign should preserve those subsystems where possible and relocate them into the new workspace model rather than replacing them wholesale.

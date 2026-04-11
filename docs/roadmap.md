# CaseForge Workspace Redesign Roadmap

Branch: `case-manager`

## Purpose

This branch exists to evolve CaseForge from a one-shot Evidence case generator into a persistent case workspace system.

The current repository already has a strong ingestion and analytical core:
- case scaffolding
- raw evidence registration
- SQL-first normalization
- downstream analytical view construction
- Evidence source extraction

The redesign does **not** throw that work away. It wraps that engine inside a broader case lifecycle model with persistent workspaces, investigator-authored sections, and multiple output targets.

## Product Reframing

CaseForge should become:

- the place an investigation begins
- the persistent workspace for the investigation while it is active
- the place structured evidence is ingested and normalized
- the place investigator-authored report sections are maintained
- the system that generates web and PDF outputs from shared sources
- the place the investigation is finalized

CaseForge should **not** remain defined primarily as:
- a single CLI session
- a generator for standalone Evidence projects
- a tool whose only meaningful output is an Evidence website

## Core Principles

1. **Case workspace first**
   - A case is a persistent workspace, not only an output site.

2. **Authoring and rendering are separate**
   - Investigators author source content.
   - Renderers consume authored content plus structured data.

3. **Shared source model**
   - Web and PDF outputs should be generated from the same canonical case inputs.

4. **Snapshots over live dependencies**
   - Outputs should be reproducible from case-local snapshots rather than depending on mutable external state.

5. **Incremental transition**
   - The existing ingestion / DuckDB / Evidence logic is reused and adapted rather than rewritten all at once.

## Target Workspace Shape

At a minimum, each case workspace will contain:

- `Sections/` — investigator-authored markdown source content
- `Sources/` — raw evidence, DuckDB, manifests, snapshots, and analytical build artifacts
- `WEB/` — generated web output(s)
- `PDF/` — generated PDF/LaTeX output(s)

Potential future additions:
- `config/`
- `logs/`
- `exports/`
- `reference/`

## Planned Milestones

### Milestone 0 — Architectural foundation
Goal:
- establish redesign docs
- capture intentional decisions
- define the first vertical slice

Deliverables:
- roadmap
- architecture overview
- decision records
- explicitly scoped first prototype

### Milestone 1 — Workspace scaffolding
Goal:
- create a persistent case workspace instead of a standalone Evidence project

Deliverables:
- case workspace generator
- `Sections/`, `Sources/`, `WEB/`, `PDF/`
- initial workspace metadata / manifest
- template-driven section scaffolding

### Milestone 2 — Canonical section model
Goal:
- establish investigator-authored section files as canonical narrative inputs

Deliverables:
- section frontmatter conventions
- section identity / placement metadata
- section parsing and validation
- case-local section snapshot build step

### Milestone 3 — Adapt existing data engine into `Sources/`
Goal:
- preserve and relocate the current ingestion / normalization / build pipeline into the workspace model

Deliverables:
- raw evidence registration in `Sources/`
- case-local DuckDB in `Sources/`
- analytical build pipeline still producing core transaction views
- test/debug support preserved

### Milestone 4 — First web renderer
Goal:
- generate one Evidence-based web output from `Sections/` + `Sources/`

Deliverables:
- renderer adapter for a single web output
- section placement logic
- section + data composition model
- regeneration path when sections or sources change

### Milestone 5 — API-first orchestration
Goal:
- move from CLI-only orchestration to an API-backed application model

Deliverables:
- FastAPI backend
- crude front-end for workspace creation and build operations
- persistent case state tracking
- CLI retained as secondary developer/operator interface

### Milestone 6 — PDF / LaTeX renderer
Goal:
- support PDF output from the same canonical case sources

Deliverables:
- LaTeX adapter
- renderer-specific templates
- output selection and regeneration rules

### Milestone 7 — Optional reference knowledge integration
Goal:
- enrich cases from controlled reference notes / knowledge sources

Deliverables:
- reference snapshot ingestion
- service / boilerplate / playbook surfaces
- reproducible case-local knowledge snapshot behavior

## First Vertical Slice

The first prototype should prove only this:

1. create case workspace
2. scaffold `Sections/`, `Sources/`, `WEB/`, `PDF/`
3. create a small set of section files from templates
4. ingest one sample evidence dataset into `Sources/`
5. build one Evidence web output from:
   - case-authored section content
   - structured case data
6. expose the flow through a thin FastAPI endpoint set

If this slice works, the redesign is viable.

## Explicit Non-Goals for the First Slice

Not in scope for the first slice:
- full PDF rendering
- final multi-user permission model
- perfect front-end UX
- complete Obsidian integration strategy
- full section schema for every future report type
- replacing every CLI path immediately

## Branch Strategy

- `main` remains the stable current-generation system.
- `case-manager` is the long-lived redesign branch.
- Work on this branch should be organized around vertical slices, not broad unbounded rewrites.
- Existing working analytical logic should be migrated into the new shape deliberately rather than discarded.

## Open Questions To Revisit Later

- exact frontmatter schema for sections
- exact section placement/composition mechanism
- shared knowledge vault vs per-case authoring workspace rules
- renderer registration model
- stale-build detection rules
- multi-user access model
- deployment model

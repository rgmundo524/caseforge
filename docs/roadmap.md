# CaseForge Roadmap

Branch: `case-manager`

## Why this roadmap changed

The redesign started as a workspace refactor, but manual smoke testing exposed several higher-level product decisions that are more important than simple renderer plumbing:

- features cannot be fixed forever at workspace initialization
- the analysis site and report site are not the same product
- canonical authored report content should stay renderer-neutral
- computed figures/tables/metrics need a shared abstraction across WEB and PDF
- PDF, API, and UI depend on those contracts and should not be designed first

Because of that, the roadmap is now organized into **tracks** rather than fragile sequential milestone numbers.

## Track A — Foundation and validated baseline

**Status:** complete

Accepted work in this track:

- redesign branch and initial architecture docs
- persistent case workspace scaffold
- section seeding and section snapshot baseline
- `Sources/` bridge to the existing engine
- runnable WEB bootstrap using shared standalone Evidence bootstrap logic
- WEB runtime/content boundary cleanup
- fresh manual end-to-end smoke validation

What is now considered stable:

- `Sections/` exists as canonical narrative source space
- `Sources/` works as the canonical data/build substrate
- `WEB/` builds a runnable Evidence output
- the existing engine remains reusable through workspace wrappers

## Track B — Feature lifecycle and output profiles

**Status:** next priority

Purpose:
- move feature control out of workspace initialization and into a workspace config
- define output profiles explicitly
- clarify rebuild and invalidation rules when features change

Planned milestones:

### B1. Config-driven feature state
Introduce a canonical YAML config file under `.caseforge/` describing:
- active features
- per-feature settings
- output profile settings
- policies such as strict validation

### B2. Output profiles
Define at least:
- `analysis_site`
- `report_site`
- `pdf_report`

### B3. Feature classes
Define feature categories such as:
- analysis features
- authoring/section seeding features
- intake/normalization features
- output-only features
- OSINT features
- cyber/infrastructure features

### B4. Rebuild rules
Document what must rerun when:
- raw exports change
- sections change
- features are enabled or disabled
- output profile settings change

### B5. Safe disable semantics
Disabling a feature must remove generated analysis/output behavior without silently deleting investigator-authored content.

## Track C — Analysis output system

**Status:** after Track B

Purpose:
- make the analysis site independent of investigator-authored narrative sections
- treat the analysis site as a generated operational workspace during active investigation

Planned milestones:

### C1. Standard analysis baseline
Always include core analysis pages and queries.

### C2. Feature-contributed analysis
Enabled features can contribute:
- SQL/views
- sources
- generated Evidence pages
- reusable computed blocks

### C3. Analysis-site profile build
`build-web-draft --profile analysis_site` should produce a generated analysis site from:
- current feature set
- current DuckDB state
- standard/generated analysis pages

### C4. Ownership boundary
Clarify which analysis pages are always generated, feature-generated, or later injected into other outputs.

## Track D — Narrative/report composition model

**Status:** after Track B, parallel with or just after Track C

Purpose:
- make report-style outputs react to the investigator-authored section tree
- keep canonical narrative content renderer-neutral

Planned milestones:

### D1. Filesystem-first section tree
`Sections/` path defines narrative hierarchy.

### D2. `index.md` and sibling semantics
Define:
- folder = page/section node
- `index.md` = page lead/body
- sibling `.md` files = ordered blocks on a page
- subfolders = child pages

### D3. Frontmatter as override
Frontmatter refines title, order, outputs, and optional placement overrides.

### D4. Fallback behavior
If placement cannot be resolved, do not silently drop authored content.

### D5. Report-site build profile
`build-web-draft --profile report_site` should build a narrative/report website from the section tree plus selected analysis content.

## Track E — Shared computed block system

**Status:** after D begins

Purpose:
- provide a renderer-neutral way to reference figures, tables, metrics, and other computed content from canonical markdown

Planned milestones:

### E1. Block registry
Features and core analysis register named blocks.

### E2. Canonical directives
Introduce CaseForge directives such as:
- `cf.metric`
- `cf.table`
- `cf.figure`

### E3. WEB adapter
Map those directives to Evidence-native output.

### E4. PDF adapter
Map the same directives to PDF/LaTeX-compatible output.

## Track F — Obsidian compatibility

**Status:** later, after Tracks D and E are stable

Purpose:
- allow canonical authored sections to take advantage of useful Obsidian ergonomics without making renderers depend on Obsidian itself

Planned milestones:

### F1. Limited syntax support
Support a controlled subset such as:
- `[[Note]]`
- `![[Note]]`

### F2. Snapshot-time resolution
Resolve links/embeds during ingestion or snapshot generation.

### F3. Optional plugin later
Potential future work:
- validation helpers
- placement autocomplete
- local preview helpers

## Track G — PDF renderer

**Status:** later, after D and E

Purpose:
- build PDF outputs from the same canonical section tree and computed block system

Planned milestones:

### G1. PDF output profile
Define `pdf_report` behavior explicitly.

### G2. PDF bootstrap/runtime
Create a stable PDF runtime/bootstrap model.

### G3. Narrative composition in PDF
Use the same canonical narrative tree.

### G4. Computed block rendering in PDF
Use the same block registry/directive model established for WEB.

## Track H — State, snapshots, API, and UI

**Status:** later

Purpose:
- make the persistent workspace experience visible and operable without changing the canonical source-of-truth model

Planned milestones:

### H1. Workspace/build state tracking
Track stale outputs, feature changes, build timestamps, and snapshots.

### H2. Snapshot/freeze model
Support preserving specific investigation points in time.

### H3. FastAPI backend
Build the orchestration layer after config/state contracts are stable.

### H4. UI
Build on top of the stable config/state model rather than becoming the source of truth.

## Superseded assumptions

The following older assumptions are now considered obsolete:

1. **Features are chosen once at workspace init**
   - superseded by config-driven feature lifecycle

2. **Analysis site depends on authored narrative sections**
   - superseded by separate analysis vs report output profiles

3. **Exact slot matching is the primary placement model**
   - superseded by filesystem-first narrative composition with frontmatter as override

4. **Canonical sections may become Evidence-native**
   - superseded by renderer-neutral computed block directives

5. **FastAPI/UI should be implemented immediately after WEB baseline**
   - superseded by the need to stabilize feature/output/content contracts first

## Immediate next work

The next code track should start with **Track B**:

1. define the YAML feature config contract
2. implement config-driven feature and output profile loading
3. keep the existing validated baseline intact while the case becomes dynamically configurable

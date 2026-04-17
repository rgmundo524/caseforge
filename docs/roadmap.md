# CaseForge Roadmap

Branch: `case-manager`

## Why this roadmap changed again

The earlier redesign established a strong workspace baseline, but deeper design work led to a larger architectural correction:

- CaseForge is not fundamentally a website project
- Quarto is not merely another renderer; it is a publishing/project system
- Evidence should remain useful, but as an analysis UI rather than the center of report truth
- report truth and analysis truth need different homes
- the project should optimize for local-first, reproducible investigation workflows rather than mandatory server-hosted sync

Because of that, the roadmap now treats:

- **CaseForge** as the canonical analysis and case system
- **Quarto** as the canonical report/project system
- **Evidence** as the interactive analysis UI

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
- feature/output-profile YAML config baseline
- init-time feature section seeding from repo-owned files

What is stable today:

- `Sections/` exists and can be seeded deterministically
- `Sources/` works as the canonical data/build substrate
- `WEB/` builds a runnable Evidence analysis site
- the existing engine remains reusable through workspace wrappers

## Track B — Local-first case workflow and config

**Status:** active

Purpose:
- make the local workspace the authoritative case
- keep sync/archival optional rather than mandatory
- make feature/output control explicit and investigator-editable

### B1. Feature config baseline
**Status:** accepted

- `.caseforge/features.yaml` is canonical
- `Sources/config/caseforge.json` syncs from active features
- `analysis_site` and `report_site` exist as output profile concepts

### B1b. Init-time feature section seeding
**Status:** accepted

- init-selected features may seed report/section scaffolds
- later feature config edits do not silently mutate the authored tree

### B2. Output profile semantics
Clarify and implement the meaning of:
- `analysis_site`
- `report_site`
- `pdf_report`
- later additional report/export profiles

### B3. Safe rebuild rules
Document and then implement what must rerun when:
- raw exports change
- report files change
- feature config changes
- output profile changes

### B4. Snapshot/freeze workflow
Define when and how the investigator captures reproducible snapshot points for analysis and report outputs.

## Track C — Canonical analysis extraction

**Status:** next

Purpose:
- identify which analysis currently lives in renderer-oriented query/page files
- extract canonical analytical truth into shared DuckDB marts/views
- keep renderer-local logic thin

Planned milestones:

### C1. Analysis inventory
Classify existing analysis into:
- canonical analytical truth
- renderer-local convenience queries
- presentational transforms only

### C2. Canonical marts/views
Move canonical aggregations and report-ready datasets into shared DuckDB-backed objects.

### C3. Chart-ready and appendix-ready outputs
Define stable outputs for:
- chart-ready datasets
- appendix tables
- report-ready summaries
- service/category aggregations

### C4. Analysis contract tests
Add tests that protect canonical analysis outputs independent of any renderer.

## Track D — Analysis-site (Evidence) as interactive UI

**Status:** after Track C begins

Purpose:
- preserve a strong live analysis experience
- stop using Evidence as the place where new canonical truth is invented

Planned milestones:

### D1. Thin analysis-site contract
Limit page-local logic to:
- filtering
- slicing
- light presentation-local transforms

### D2. Feature-contributed analysis pages
Enabled features can contribute:
- analysis pages
- source queries
- reusable visual blocks

### D3. Analysis-site profile build
`build-analysis-site` or equivalent should generate the analysis UI from:
- current feature state
- canonical analysis marts/views
- standard/generated analysis pages

### D4. Optional future dashboard evaluation
Evaluate whether some analysis outputs fit better as Quarto dashboards later, without removing the Evidence path prematurely.

## Track E — Quarto report system

**Status:** next, in parallel with Track C planning

Purpose:
- make Quarto the canonical report/project system
- stop trying to hand-build a publishing system inside CaseForge

Planned milestones:

### E1. Quarto project contract
Define the generated Quarto project structure, config, profiles, data ingress, and output contract.

### E2. Report authoring tree becomes Quarto-native
Move the canonical report tree toward `.qmd` for rendered report outputs while keeping freeform notes/reference material separate.

### E3. Report profiles
Map CaseForge report intentions to Quarto profiles, e.g.:
- `report_site`
- `pdf_report`
- later notices/letters/summary variants

### E4. Quarto proof of concept
Generate a minimal Quarto report project from:
- canonical analysis outputs
- authored report files
- current feature/profile config

### E5. Typst-backed PDF evaluation
Use Quarto’s Typst output path to assess whether it is suitable for the primary formal report workflow.

## Track F — Report authoring and composition

**Status:** after E1/E2 are stable

Purpose:
- define how authored report files become a coherent report across HTML/PDF outputs

Planned milestones:

### F1. Filesystem-first report tree
A directory tree defines report hierarchy.

### F2. `index.qmd` and sibling semantics
Define:
- folder = report node
- `index.qmd` = page/chapter metadata + lead/body
- sibling files = ordered blocks on that page
- subfolders = child pages

### F3. Frontmatter as refinement
Use frontmatter to refine title, order, outputs, and report-specific behavior.

### F4. Deterministic composition/fallbacks
Never silently drop authored content when composition cannot be resolved.

## Track G — Shared computed block system

**Status:** after Tracks C and E are underway

Purpose:
- provide a shared way for report files to reference computed figures, tables, metrics, and blocks without duplicating heavy analysis logic

Planned milestones:

### G1. Block registry
Core analysis and features register named blocks.

### G2. Canonical directives
Introduce renderer-aware but report-author-friendly directives such as:
- `cf.metric`
- `cf.table`
- `cf.figure`

### G3. Quarto mapping
Map block references into Quarto report outputs.

### G4. Evidence mapping
Optionally map the same blocks into analysis-site widgets where appropriate.

## Track H — Obsidian / note ecosystem support

**Status:** later

Purpose:
- preserve investigator-friendly local authoring while keeping renderers independent

Planned milestones:

### H1. Note/reference separation
Distinguish canonical report files from freeform notes/reference material.

### H2. Limited Obsidian syntax support
Support a controlled subset such as:
- `[[Note]]`
- `![[Note]]`

### H3. Snapshot-time resolution
Resolve supported links/embeds during build or snapshot generation rather than inside renderers.

## Track I — API and UI

**Status:** later

Purpose:
- improve usability without making UI the source of truth

Planned milestones:

### I1. Local application shell
Wrap the local-first workflow in a local executable/app experience.

### I2. Workspace/build state visibility
Show stale outputs, feature changes, build timestamps, and snapshot information.

### I3. Optional server mode later
Only after the local-first workflow is solid should server-hosted coordination be considered.

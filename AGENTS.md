# AGENTS.md

This repository uses a design-first workflow for substantial changes on branch `case-manager`.

## Read this first

Before implementing anything on `case-manager`, read these files in order:

1. `docs/architecture.md`
2. `docs/roadmap.md`
3. `docs/decisions/`
4. `docs/contracts/`
5. `docs/reference/quarto-capabilities.md`
6. the task-specific spec in `specs/` or the engineering handoff you were given

If documents conflict, the precedence order is:

1. `docs/contracts/*`
2. `docs/decisions/*`
3. `docs/architecture.md`
4. `docs/roadmap.md`
5. `docs/reference/*`
6. task-specific implementation specs

## Branch context

`case-manager` is a long-lived redesign branch.

The redesign goal is no longer “generate an Evidence case site.” The current target is:

- **CaseForge** as the case-analysis application and canonical data engine
- **Quarto** as the canonical report/project/publishing system
- **Evidence** as an analyst-facing interactive analysis UI

A case workspace remains the canonical object. It contains:

- `Sections/` — canonical report authoring tree (moving toward `.qmd`)
- `Sources/` — canonical data/build substrate
- `WEB/` — generated analysis-site outputs (currently Evidence)
- `PDF/` — legacy placeholder for future generated report outputs
- `.caseforge/` — workspace metadata and config

## Accepted baseline as of the latest validated smoke runs

The following foundation work is considered accepted:

- persistent workspace scaffold
- section seeding and section snapshot baseline
- `Sources/` bridge to the existing engine
- runnable WEB bootstrap using the shared standalone Evidence bootstrap path
- runtime/content boundary cleanup so starter demo content does not leak into final WEB outputs
- feature/output-profile config under `.caseforge/features.yaml`
- init-time feature section seeding from repo-owned seed files
- fresh end-to-end smoke path:
  - `init-workspace`
  - `add-files`
  - `normalize`
  - `build-db`
  - `build-web-draft`
  - `npm install`
  - `npm run sources`
  - `npm run dev`

## Current design rules

### Canonical analysis truth is renderer-independent
Analytical truth belongs in DuckDB / shared SQL / canonical marts and views.

### Quarto is the canonical report system
Report structure, profile-aware report composition, and multi-format report rendering should target Quarto rather than a bespoke CaseForge publishing layer.

### Evidence is the analysis UI
Evidence remains useful for analyst-facing and interactive outputs, but should stop accumulating canonical report truth and deep canonical analysis logic.

### Local-first is the primary operating model
The primary case workspace should live on the investigator’s machine. Sync, archival, and sharing are secondary concerns, not the default execution model.

### `Sections/` is the canonical report authoring tree
The report tree should move toward `.qmd` as the default authoring format for report outputs. Freeform notes and supporting material may still remain plain `.md` elsewhere.

### Features are config-driven, but section tree mutation is init-time only
Features can change build/runtime behavior after workspace creation, but post-init config changes must not silently mutate the investigator’s authored report tree.

## Things not to reintroduce

Do not reintroduce any of the following without an explicit new ADR:

- repo-owned mini Evidence runtime scaffolds
- immutable features chosen only at workspace init
- analysis-site dependence on authored report sections
- heavy canonical analysis hidden inside renderer pages
- bespoke publishing/runtime orchestration that duplicates what Quarto already provides
- silent dropping of authored report content when composition fails

## Testing commands

Use these as the default lightweight validation commands:

```bash
python -m unittest discover -s tests -p 'test_workspace*.py'
```

When working on the current Evidence analysis-site path, use a fresh manual smoke flow after tests pass:

```bash
python tools/CaseWorkspace.py init-workspace ...
python tools/CaseWorkspace.py add-files ...
python tools/CaseWorkspace.py normalize --workspace-root ...
python tools/CaseWorkspace.py build-db --workspace-root ...
python tools/CaseWorkspace.py build-web-draft --workspace-root ...
cd WEB/<output-name>
npm install
npm run sources
npm run dev
```

For future Quarto work, tests should add an equivalent local render/proof step rather than assuming the Evidence smoke flow is sufficient.

## Documentation expectations

For design-heavy changes:

- update or add ADRs in `docs/decisions/`
- update the relevant contract docs in `docs/contracts/`
- update `docs/roadmap.md` if track sequencing changes
- update `docs/architecture.md` if the system model changes
- update `docs/reference/quarto-capabilities.md` if Quarto assumptions change
- update `docs/workflows/investigator-lifecycle.md` when workflow expectations change

## Implementation guidance

Prefer:

- additive changes
- deterministic behavior
- explicit config and schema validation
- reusable seams over duplicated logic
- renderer-independent analysis truth
- Quarto-native report/project conventions where they improve workflow

Avoid:

- hidden coupling to shell cwd when explicit config can exist
- custom ad hoc feature behavior without a declared schema
- placing deep canonical analysis in page-level renderer logic
- building a bespoke publishing layer when Quarto can already provide the same capability

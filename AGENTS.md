# AGENTS.md

This repository uses a design-first workflow for substantial changes on branch `case-manager`.

## Read this first

Before implementing anything on `case-manager`, read these files in order:

1. `docs/architecture.md`
2. `docs/roadmap.md`
3. `docs/decisions/`
4. `docs/contracts/`
5. the task-specific spec in `specs/` or the engineering handoff you were given

If documents conflict, the precedence order is:

1. `docs/contracts/*`
2. `docs/decisions/*`
3. `docs/architecture.md`
4. `docs/roadmap.md`
5. task-specific implementation specs

## Branch context

`case-manager` is a long-lived redesign branch.

The redesign goal is to evolve CaseForge from a one-shot Evidence case generator into a persistent case workspace system.

A case workspace is the canonical object. It contains:

- `Sections/` — canonical investigator-authored narrative content
- `Sources/` — canonical data/build substrate
- `WEB/` — generated Evidence outputs
- `PDF/` — future generated PDF outputs
- `.caseforge/` — workspace metadata and config

## Accepted baseline as of the latest smoke test

The following foundation work is considered accepted:

- persistent workspace scaffold
- section seeding and section snapshot baseline
- `Sources/` bridge to the existing engine
- runnable WEB bootstrap using the shared standalone Evidence bootstrap path
- runtime/content boundary cleanup so starter demo content does not leak into final WEB outputs
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

### Features are config-driven, not init-only
Features are not fixed forever at workspace initialization. A case should be able to enable or disable features over time through a workspace config file.

### Analysis site and report site are different outputs
The analysis site should not depend on investigator-authored narrative sections.

The report site should react to the `Sections/` tree plus selected analysis outputs.

### `Sections/` is canonical for narrative/report authorship
Do not make Evidence-native markdown the canonical authored source for report content.

### Evidence runtime bootstrap is reused
Do not reintroduce a hand-maintained mini Evidence runtime inside CaseForge.

Use the existing standalone bootstrap seam and then overlay CaseForge-owned content.

### WEB ownership boundary
After runtime bootstrap, `pages/` and `sources/` are CaseForge-owned content surfaces.

Root runtime files such as `package.json`, `package-lock.json`, `.npmrc`, `degit.json`, and runtime scripts are bootstrap-owned and must remain intact.

## Things not to reintroduce

Do not reintroduce any of the following without an explicit new ADR:

- repo-owned mini Evidence runtime scaffolds
- immutable features chosen only at workspace init
- analysis-site dependence on investigator-authored `.md` sections
- Evidence-native canonical authored sections
- silent dropping of authored content when placement fails

## Testing commands

Use these as the default lightweight validation commands:

```bash
python -m unittest discover -s tests -p 'test_workspace*.py'
```

When working on WEB output behavior, use a fresh manual smoke flow after tests pass:

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

## Documentation expectations

For design-heavy changes:

- update or add ADRs in `docs/decisions/`
- update the relevant contract docs in `docs/contracts/`
- update `docs/roadmap.md` if milestone/track sequencing changes
- update `docs/architecture.md` if the system model changes

## Implementation guidance

Prefer:

- additive changes
- deterministic behavior
- explicit config and schema validation
- reusable seams over duplicated logic
- filesystem-first composition for canonical narrative sections

Avoid:

- hidden coupling to shell cwd when explicit config can exist
- custom ad hoc feature behavior without a declared schema
- mixing renderer-specific authoring into canonical narrative sources

# CaseForge Engineering Handoff

## 1. 🎯 Objective (Non-Negotiable Goal)

Replace the current flat / partially nested `Sections/` seed shape with a **filesystem-first narrative section tree** for `init-workspace`.

This task must:

- update init-time section seeding to produce the new directory structure under `Sections/`
- make `index.md` the page-level file for each seeded page node
- keep feature-selected section seeds as repo-owned files layered on top of common/template seeds
- preserve the rule that **only `init-workspace` automatically shapes investigator-authored `Sections/`**
- keep post-init feature YAML edits from mutating `Sections/`

This task is **not** full nested section composition yet. It only updates the seeded authored tree and the init-time seeding logic.

---

## 2. 🧠 Context (System Understanding)

Current accepted baseline on `case-manager`:

- persistent workspace scaffold exists
- `.caseforge/features.yaml` is canonical feature/output-profile state
- `Sources/` bridges to the legacy engine
- `WEB/` bootstraps a real Evidence app and builds successfully
- B1b added repo-owned section seeds under:
  - `templates/common/section-seeds/`
  - `templates/features/<feature>/section-seeds/`

Current B1b seed shape is mechanically correct but structurally wrong for the intended authored narrative model. It currently creates things like:

- `Sections/case-background.md`
- `Sections/client-narrative.md`
- `Sections/Investigative-Notes/cross-chain-activity.md`
- `Sections/Investigative-Notes/url-domain-observations.md`

We have now decided the canonical narrative/report source tree should be **filesystem-first** and modeled more closely on Evidence’s page-tree approach.

Important accepted design constraints:
- `analysis_site` must remain independent of authored narrative sections
- `Sections/` is canonical for narrative/report authoring
- `init-workspace` may seed `Sections/`
- later edits to `.caseforge/features.yaml` must not silently mutate `Sections/`

---

## 3. 📐 Design Intent (Critical)

The investigator-authored narrative tree should communicate structure through the filesystem.

Rules:

### Page nodes
- `Sections/<Page>/index.md` defines a page node
- page-level metadata lives in `index.md`
- the body of `index.md` may contain lead/body text for that page

### Page blocks
- `Sections/<Page>/<Block>.md` is an ordered content block on that page
- non-`index.md` files in a page folder do **not** create child pages

### Child pages
- `Sections/<Page>/<ChildPage>/index.md` defines a child page

### Ordering
- page order comes from `index.md` frontmatter `order`
- block order comes from each block file frontmatter `order`
- fallback ordering may remain filename-based if needed, but this milestone does not implement full composition yet

### Placement
For these seeded narrative/report files, **path is placement**.
Do **not** require `placement_key` in the new seeded files.

### Output targeting
These seeded narrative files are for:
- `report_site`
- `pdf_report`

They are not required for `analysis_site`.

### Seeding ownership
- base/common seeds own page skeletons
- feature seeds only add leaf blocks unless explicitly specified otherwise
- later feature toggles do not mutate `Sections/`

---

## 4. 🧱 Schema + Naming Contracts

### New canonical seeded tree for the current default + selected features example

When `init-workspace` is called with:
- `--template default`
- `--feature cross-chain-activity`
- `--feature urls`

the seeded `Sections/` tree must be:

```text
Sections/
├── Appendix/
│   ├── index.md
│   └── transactions.md
├── Conclusion/
│   ├── conclusion.md
│   ├── index.md
│   ├── investigative-findings.md
│   └── limitations.md
├── Intro/
│   ├── case-background.md
│   ├── client-narrative.md
│   └── index.md
├── Methodology/
│   └── index.md
├── Off-Chain/
│   ├── index.md
│   └── urls.md
└── On-Chain/
    ├── cross-chain-activity.md
    └── index.md
```

### Repo-owned seed source locations

Common/base seed source must move to:

```text
templates/common/section-seeds/
  Appendix/
    index.md
    transactions.md
  Conclusion/
    index.md
    conclusion.md
    investigative-findings.md
    limitations.md
  Intro/
    index.md
    case-background.md
    client-narrative.md
  Methodology/
    index.md
  Off-Chain/
    index.md
  On-Chain/
    index.md
```

Feature-owned leaf seed sources:

```text
templates/features/cross-chain-activity/section-seeds/
  On-Chain/
    cross-chain-activity.md

templates/features/urls/section-seeds/
  Off-Chain/
    urls.md
```

### Page-level frontmatter contract (`index.md`)

```yaml
---
page_id: intro
title: Introduction
order: 10
outputs:
  - report_site
  - pdf_report
page_kind: section
status: draft
---
```

### Block-level frontmatter contract (non-`index.md`)

```yaml
---
block_id: case_background
title: Case Background
order: 10
outputs:
  - report_site
  - pdf_report
content_class: case_authored
status: draft
---
```

### Minimum exact seed contents

Use the following exact or substantially equivalent placeholder content.

#### `templates/common/section-seeds/Intro/index.md`

```md
---
page_id: intro
title: Introduction
order: 10
outputs:
  - report_site
  - pdf_report
page_kind: section
status: draft
---

# Introduction

Use this page to introduce the case, the victim, and the overall scope of the investigation.
```

#### `templates/common/section-seeds/Intro/case-background.md`

```md
---
block_id: case_background
title: Case Background
order: 10
outputs:
  - report_site
  - pdf_report
content_class: case_authored
status: draft
---

## Case Background

Summarize the case context, relevant parties, and the high-level investigative objective.
```

#### `templates/common/section-seeds/Intro/client-narrative.md`

```md
---
block_id: client_narrative
title: Client Narrative
order: 20
outputs:
  - report_site
  - pdf_report
content_class: case_authored
status: draft
---

## Client Narrative

Capture the client-provided narrative, including key dates, communications, and claimed losses.
```

#### `templates/common/section-seeds/Methodology/index.md`

```md
---
page_id: methodology
title: Methodology
order: 20
outputs:
  - report_site
  - pdf_report
page_kind: section
status: draft
---

# Methodology

Describe the investigative methods, data sources, and analytical approach used in this matter.
```

#### `templates/common/section-seeds/On-Chain/index.md`

```md
---
page_id: on_chain
title: On-Chain Analysis
order: 30
outputs:
  - report_site
  - pdf_report
page_kind: section
status: draft
---

# On-Chain Analysis

Summarize the major on-chain findings and organize blockchain-specific analysis blocks on this page.
```

#### `templates/features/cross-chain-activity/section-seeds/On-Chain/cross-chain-activity.md`

```md
---
block_id: cross_chain_activity
title: Cross-Chain Activity
order: 10
outputs:
  - report_site
  - pdf_report
content_class: case_authored
status: draft
---

## Cross-Chain Activity

Document cross-chain movements, suspected bridge usage, and any related narrative observations.
```

#### `templates/common/section-seeds/Off-Chain/index.md`

```md
---
page_id: off_chain
title: Off-Chain Analysis
order: 40
outputs:
  - report_site
  - pdf_report
page_kind: section
status: draft
---

# Off-Chain Analysis

Summarize off-chain investigative work, including identifiers, domains, communications, and other external indicators.
```

#### `templates/features/urls/section-seeds/Off-Chain/urls.md`

```md
---
block_id: urls
title: URLs
order: 10
outputs:
  - report_site
  - pdf_report
content_class: case_authored
status: draft
---

## URLs

Document relevant websites, URLs, and domain-based observations tied to the investigation.
```

#### `templates/common/section-seeds/Conclusion/index.md`

```md
---
page_id: conclusion
title: Conclusion
order: 50
outputs:
  - report_site
  - pdf_report
page_kind: section
status: draft
---

# Conclusion

Use this page to summarize findings, state conclusions, and capture limitations.
```

#### `templates/common/section-seeds/Conclusion/investigative-findings.md`

```md
---
block_id: investigative_findings
title: Investigative Findings
order: 10
outputs:
  - report_site
  - pdf_report
content_class: case_authored
status: draft
---

## Investigative Findings

Summarize the principal findings established by the evidence and analysis.
```

#### `templates/common/section-seeds/Conclusion/conclusion.md`

```md
---
block_id: conclusion
title: Conclusion
order: 20
outputs:
  - report_site
  - pdf_report
content_class: case_authored
status: draft
---

## Conclusion

State the investigator’s conclusions in clear, supportable terms.
```

#### `templates/common/section-seeds/Conclusion/limitations.md`

```md
---
block_id: limitations
title: Limitations
order: 30
outputs:
  - report_site
  - pdf_report
content_class: case_authored
status: draft
---

## Limitations

List investigative limitations, assumptions, and known gaps affecting the analysis.
```

#### `templates/common/section-seeds/Appendix/index.md`

```md
---
page_id: appendix
title: Appendix
order: 60
outputs:
  - report_site
  - pdf_report
page_kind: section
status: draft
---

# Appendix

Use this page for supporting material, supplementary explanations, and referenced artifacts.
```

#### `templates/common/section-seeds/Appendix/transactions.md`

```md
---
block_id: transactions
title: Transactions
order: 10
outputs:
  - report_site
  - pdf_report
content_class: reference
status: draft
---

## Transactions

Use this section for transaction-specific appendix material or supporting notes.
```

---

## 5. ⚙️ Required Changes (Task List)

1. Replace the current common `section-seeds` tree with the filesystem-first page/block tree above.
2. Replace the current feature seed paths:
   - remove `Investigative-Notes/cross-chain-activity.md`
   - remove `Investigative-Notes/url-domain-observations.md`
   - add the new `On-Chain/cross-chain-activity.md`
   - add the new `Off-Chain/urls.md`
3. Update any init-time seeding tests so they assert the new directory structure and file names.
4. Keep the existing deterministic seeding layer order:
   - common
   - primary template
   - selected features in explicit init order
5. Preserve the existing guarantee that later YAML edits/rebuilds do **not** mutate `Sections/`.
6. Do **not** yet implement nested section snapshotting or nested report-site composition logic.
7. Do **not** yet change `analysis_site` behavior.

---

## 6. 🔗 Dependency Awareness

This task affects:
- `init_workspace(...)`
- repo-owned section seed source files
- tests that assert seeded `Sections/` structure
- future narrative/report composition work

It should **not** alter:
- current `Sources/` engine bridge
- `analysis_site` generation logic
- WEB bootstrap logic
- current feature config YAML behavior
- post-init `Sections/` immutability

---

## 7. 🧪 Validation Criteria

Success means all of the following are true:

1. A fresh workspace initialized with:
   - `--feature cross-chain-activity`
   - `--feature urls`
   yields the exact seeded tree shown above.

2. The repo now contains repo-owned seed source files in:
   - `templates/common/section-seeds/...`
   - `templates/features/cross-chain-activity/section-seeds/On-Chain/...`
   - `templates/features/urls/section-seeds/Off-Chain/...`

3. The old `Investigative-Notes/...` seed shape is gone from active init output.

4. Post-init edits to `.caseforge/features.yaml` still do not mutate `Sections/`.

5. Existing workspace tests continue to pass.

---

## 8. ⚠️ Edge Cases

- Missing `section-seeds/` directories remain a no-op.
- Layer collisions remain overwrite-by-layer, as already accepted.
- Feature seeds must not own parent `index.md` files that are already owned by common/base seeds.
- This milestone must not assume nested `Sections/` are already parsed by the report composition system.
- File/directory names must match the target tree exactly, including:
  - `Intro`
  - `Methodology`
  - `On-Chain`
  - `Off-Chain`
  - `Conclusion`
  - `Appendix`

---

## 9. 🚫 Non-Goals

- Do NOT implement full filesystem-first report composition yet.
- Do NOT change `analysis_site` behavior.
- Do NOT change feature config YAML semantics.
- Do NOT add post-init reseeding commands.
- Do NOT invent new section lifecycle modes.
- Do NOT redesign WEB bootstrap, `Sources`, or PDF rendering.

---

## 10. 📁 File Scope

Changes should be limited to:
- `caseforge/workspace.py`
- `tests/test_workspace.py`
- `templates/common/section-seeds/...`
- `templates/features/cross-chain-activity/section-seeds/...`
- `templates/features/urls/section-seeds/...`

If additional test files must change, keep that narrowly scoped and explain why.

---

## Explicit answers required in Codex return

1. Which old seed paths were removed from the active init output?
2. Which new repo-owned seed files were added under `templates/common/section-seeds/`?
3. Which new repo-owned feature seed files were added?
4. What exact test proves a fresh workspace now produces the new tree shape?
5. What exact test still proves later YAML edits do not mutate `Sections/`?

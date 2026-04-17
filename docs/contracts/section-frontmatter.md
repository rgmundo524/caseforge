# Report Tree Frontmatter Contract

> Status: draft contract

## Purpose

This document defines the frontmatter fields for canonical report files under `Sections/`.

These files should move toward `.qmd` for rendered report outputs.

## Two file roles

### Page files (`index.qmd`)
These define page/chapter metadata plus optional page lead/body content.

Illustrative shape:

```yaml
page_id: intro
title: Introduction
order: 10
outputs:
  - report_site
  - pdf_report
page_kind: section
status: draft
```

### Block files (sibling `.qmd` files)
These define ordered blocks that live on a page.

Illustrative shape:

```yaml
block_id: case_background
title: Case Background
order: 10
outputs:
  - report_site
  - pdf_report
content_class: case_authored
status: draft
```

## Current intended fields

### Page-level fields
- `page_id` — stable identifier for the page
- `title` — display title
- `order` — ordering among sibling pages
- `outputs` — which output profiles include the page
- `page_kind` — classification of page node
- `status` — draft/final/other lifecycle marker

### Block-level fields
- `block_id` — stable identifier for the block
- `title` — display title
- `order` — ordering among sibling blocks
- `outputs` — which output profiles include the block
- `content_class` — narrative/reference/generated/etc.
- `status` — draft/final/other lifecycle marker

## Design note

Path is the primary placement signal for the report tree.

Frontmatter refines:
- ordering
- display metadata
- output targeting
- page/block classification

It should not be used to recreate a rigid slot-matching system for the canonical report tree.

# Section Frontmatter Contract

> Status: draft contract

## Purpose

This document defines the canonical frontmatter fields for investigator-authored narrative section files.

These files live under `Sections/` and are the canonical authored source for narrative/report outputs.

## Current required baseline fields

Current seeded sections already use:

```yaml
section_id: conclusions
title: Conclusions
content_class: case_authored
placement_key: report.conclusions
outputs:
  - web
  - pdf
status: draft
```

## Current required fields

### `section_id`
Required non-empty string.
Stable identifier for the section.

### `title`
Required non-empty string.
Human-readable title.

### `content_class`
Required non-empty string.
Current baseline value: `case_authored`.

### `placement_key`
Required non-empty string.
Currently used as semantic placement information.

### `outputs`
Required non-empty list of output ids.
Current baseline values include `web` and `pdf`.

### `status`
Required non-empty string.
Current baseline value: `draft`.

## Planned future optional fields

As the filesystem-first composition model evolves, likely optional fields include:
- `order`
- `page_id`
- `parent_page`
- `placement_mode`
- `strict`

## Design note

Frontmatter should refine placement and behavior, but the long-term composition model should remain filesystem-first for narrative/report outputs.

# Section Tree Composition Contract

> Status: draft contract

## Purpose

This document defines the target filesystem-first composition model for narrative/report outputs.

The key rule is:

- the file tree communicates the default report structure
- frontmatter refines the defaults

## Target model

### Folder
A folder represents a page or section node.

### `index.md`
Defines the page lead/body and page-level metadata.

### Sibling markdown files
Non-`index.md` markdown files in the same folder define ordered blocks on that page.

### Subfolders
Subfolders define child pages.

## Illustrative example

```text
Sections/
  Report/
    Background/
      index.md
      client-narrative.md
      case-background.md
    Findings/
      index.md
      investigative-findings.md
    Conclusion/
      index.md
      conclusions.md
      limitations.md
```

## Placement principles

- moving files or folders changes structure predictably
- report placement should not require editing WEB templates for every new investigator section
- exact slots/anchors may still exist later as precision tools, but they are not the primary placement model

## How the tree starts

The initial tree may be seeded by:
- the base workspace template
- feature scaffolds explicitly selected at `init-workspace`

After init, the section tree should be treated as investigator-owned. Post-init feature config edits should not silently add/remove/move section files.

## Fallback rule

If placement cannot be resolved:
- do not silently drop content
- use a deterministic fallback or fail in strict mode

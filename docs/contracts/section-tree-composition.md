# Section Tree Composition Contract

> Status: draft contract

## Purpose

This document defines the target filesystem-first composition model for canonical report outputs.

The key rule is:
- the file tree communicates the default report structure
- frontmatter refines the defaults

## Default rendered format

For rendered report outputs, the canonical report tree should move toward `.qmd`.

Plain `.md` remains appropriate for:
- freeform notes
- scratch material
- reference/supporting material
- internal docs

## Target model

### Folder
A folder represents a report page/chapter/section node.

### `index.qmd`
Defines the page lead/body and page-level metadata.

### Sibling files
Non-`index.qmd` files in the same folder define ordered blocks on that page.

### Subfolders
Subfolders define child pages.

## Illustrative example

```text
Sections/
  Intro/
    index.qmd
    case-background.qmd
    client-narrative.qmd
  On-Chain/
    index.qmd
    cross-chain-activity.qmd
  Conclusion/
    index.qmd
    investigative-findings.qmd
    conclusion.qmd
    limitations.qmd
```

## Placement principles

- moving files or folders changes structure predictably
- report placement should not require editing analysis-site templates for every new investigator section
- exact anchors/slots may exist later as precision tools, but they are not the primary placement model

## How the tree starts

The initial report tree may be seeded by:
- the base workspace template
- feature scaffolds explicitly selected at `init-workspace`

After init, the report tree should be treated as investigator-owned. Post-init feature config edits should not silently add/remove/move report files.

## Fallback rule

If composition cannot be resolved:
- do not silently drop content
- use a deterministic fallback or fail in strict mode

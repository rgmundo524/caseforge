# ADR 0007: `Sections/` is the canonical authored source for narrative outputs

- Status: Accepted
- Date: 2026-04-12

## Context

WEB outputs are generated artifacts and should not become the main authoring surface.

The project also intends to support PDF outputs later, so the canonical authored source cannot be tightly coupled to Evidence-native syntax.

## Decision

`Sections/` is the canonical authored source for narrative/report content.

The target composition model is filesystem-first:
- folder path communicates page hierarchy
- `index.md` communicates page lead/body
- sibling markdown files communicate page blocks
- frontmatter refines the default behavior

## Consequences

- report outputs can react to the investigator-authored section tree
- WEB is no longer the authoring surface for narrative content
- PDF can later consume the same authored tree
- exact slot matching is not the primary authoring model

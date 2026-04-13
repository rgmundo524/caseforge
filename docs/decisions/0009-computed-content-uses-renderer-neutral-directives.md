# ADR 0009: Computed content uses renderer-neutral directives

- Status: Accepted
- Date: 2026-04-12

## Context

Canonical section content will need to reference computed values, tables, and figures.

Making canonical sections Evidence-native would simplify WEB in the short term but create a harder PDF problem later.

## Decision

Canonical markdown will remain renderer-neutral.

Computed content will later be represented by CaseForge-native directives and a shared block registry rather than raw Evidence-native components.

Illustrative examples:
- `cf.metric`
- `cf.table`
- `cf.figure`

## Consequences

- WEB can still render rich Evidence-native outputs
- PDF can later render the same directives through a different adapter
- feature-contributed analysis blocks become reusable across output profiles
- canonical authored content avoids becoming renderer-specific

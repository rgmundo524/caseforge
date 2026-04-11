# ADR 0002: Canonical authored content is separate from generated output

- Status: Accepted
- Date: 2026-04-11

## Context

Investigators need to write case-specific material that cannot be reliably automated, including:
- factual background
- client narrative
- interpretive findings
- limitations
- conclusions
- custom appendix material

At the same time, CaseForge needs to generate web and PDF outputs and preserve structured evidence and analytical results.

If authored content is tightly bound to renderer-specific files, the system becomes fragile:
- authorship gets trapped inside one output format
- adding new renderers becomes harder
- output files start behaving like canonical truth
- reproducibility and reuse get worse

## Decision

CaseForge will treat investigator-authored markdown as **canonical source content** that is distinct from renderer-specific generated output.

This means:
- investigators author source sections in `Sections/`
- renderers consume those sections together with structured data from `Sources/`
- `WEB/` and `PDF/` are output workspaces, not the primary home of canonical narrative truth

## Consequences

### Positive
- supports multiple output targets from the same case content
- preserves human authorship without forcing it into web/pdf-specific formats
- improves portability and reuse
- makes section metadata and validation possible
- keeps renderer-specific concerns separate from source content

### Tradeoffs
- requires a composition/placement model
- requires section metadata conventions
- adds a build step between authoring and rendering

## Follow-on Implications

This decision implies:
- section files should have clear identities and metadata
- renderers need a section-consumption contract
- case builds should snapshot or validate section content before rendering

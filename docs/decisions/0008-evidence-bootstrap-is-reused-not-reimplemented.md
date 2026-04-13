# ADR 0008: Evidence bootstrap is reused, not reimplemented

- Status: Accepted
- Date: 2026-04-12

## Context

Several redesign iterations drifted into creating a separate mini runtime scaffold for Evidence inside CaseForge.

That created the wrong abstraction boundary. CaseForge templates are overlays and analysis contributions, not a second independently maintained Evidence starter.

## Decision

WEB outputs must reuse the existing standalone Evidence bootstrap seam rather than reimplementing an Evidence runtime inside the repository.

After bootstrap:
- bootstrap-owned runtime root files remain intact
- CaseForge owns `pages/` and `sources/` content
- datasource linkage is updated to point back to `Sources/data/case.duckdb`

## Consequences

- Evidence runtime drift is reduced
- bootstrap/runtime issues stay aligned with the shared standalone path
- CaseForge focuses on case-specific overlays and generated content rather than runtime ownership

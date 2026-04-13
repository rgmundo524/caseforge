# ADR 0011: Init-selected features seed section scaffolds once

- Status: Accepted
- Date: 2026-04-13

## Context

Investigators need a strong initial section structure when a case starts.

If `init-workspace` is called with explicit features such as `cross-chain-activity` or `urls`, it should be able to seed relevant investigator-facing section scaffolds under `Sections/`.

However, automatically mutating the investigator's section tree later in a live case would be risky and confusing.

## Decision

CaseForge should treat feature-related section scaffolds as an init-time concern.

The rule is:

- features explicitly selected during `init-workspace` may seed section scaffolds
- later edits to `.caseforge/features.yaml` affect builds and generated outputs
- later edits to `.caseforge/features.yaml` do **not** automatically restructure `Sections/`

If a future workflow needs post-init section seeding, that must be implemented as an explicit investigator action, not as an automatic side effect of config parsing.

## Consequences

- investigators get a better starting structure
- the authored section tree remains stable and investigator-owned after init
- feature config remains safe to edit during the investigation
- the project does not need speculative section-seeding lifecycle modes before the explicit command exists

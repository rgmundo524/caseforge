# Feature Extension Schema

> Status: draft contract

## Purpose

This document defines the planned schema for adding new CaseForge features in a structured, reusable way.

The goal is to avoid one-off custom feature behavior.

## Conceptual feature manifest

Illustrative YAML shape:

```yaml
id: cross_chain
category: analysis
label: Cross-chain activity
summary: Cross-chain tracing and matching analysis

contributes:
  sql_views: true
  source_queries: true
  analysis_pages: true
  section_seed_scaffolds: true
  computed_blocks: true

build_impacts:
  requires_add_files: false
  requires_normalize: false
  requires_build_db: true
  requires_web_rebuild: true
  requires_pdf_rebuild: false

defaults:
  enabled: false
  settings:
    matching_mode: balanced
    defi_swap_matching: true

section_seed_scaffolds:
  - path: Sections/Report/Analysis/Cross-Chain/index.md
    template: section-seeds/cross-chain/index.md
  - path: Sections/Appendix/Cross-Chain/notes.md
    template: section-seeds/cross-chain/notes.md
```

## Required concepts

A feature definition should declare:
- identity
- category/family
- contributions
- build impacts
- defaults

If a feature contributes investigator-facing scaffolds, it should declare them explicitly.

## Section seeding policy

The current design policy is:

- init-selected features may seed section scaffolds during `init-workspace`
- post-init edits to `.caseforge/features.yaml` do **not** automatically mutate `Sections/`
- if later we support post-init seeding, it should be an explicit investigator action

Because that later command does not exist yet, the schema should **not** invent unnecessary lifecycle modes for section seeding today.

If a future explicit reseed command exists, the schema can grow then.

## Planned feature families

Examples:
- blockchain analysis
- OSINT
- cyber/infrastructure
- legal/process
- output-only/reporting

## Contribution buckets

Planned contribution types:
- SQL/views
- source queries
- generated WEB pages
- section seed scaffolds/prompts
- computed block registrations
- future PDF fragments

## Design goal

A future feature should be addable by following a schema and known extension points, not by inventing a custom workflow each time.

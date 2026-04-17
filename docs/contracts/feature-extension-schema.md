# Feature Extension Schema

> Status: draft contract

## Purpose

This document defines the planned schema for adding new CaseForge features in a structured, reusable way.

The goal is to avoid one-off custom feature behavior.

## Conceptual feature manifest

Illustrative YAML shape:

```yaml
id: cross-chain-activity
category: blockchain_analysis
label: Cross-chain activity
summary: Cross-chain tracing and matching analysis

contributes:
  canonical_analysis_sql: true
  analysis_site_pages: true
  analysis_site_sources: true
  report_section_seed_scaffolds: true
  report_blocks: true
  quarto_partials: false

build_impacts:
  requires_add_files: false
  requires_normalize: false
  requires_build_db: true
  requires_analysis_site_rebuild: true
  requires_report_rebuild: true

defaults:
  enabled: false
  settings:
    matching_mode: balanced
    defi_swap_matching: true

report_section_seed_scaffolds:
  - path: Sections/On-Chain/cross-chain-activity.qmd
    template: section-seeds/On-Chain/cross-chain-activity.qmd

report_blocks:
  - id: cross_chain_pairs_overview
    source: canonical-analysis/cross_chain_pairs.sql
```

## Required concepts

A feature definition should declare:
- identity
- category/family
- contributions
- build impacts
- defaults

If a feature contributes investigator-facing report scaffolds, it should declare them explicitly.

## Section seeding policy

The current design policy is:

- init-selected features may seed report scaffolds during `init-workspace`
- post-init edits to `.caseforge/features.yaml` do **not** automatically mutate `Sections/`
- if later we support post-init seeding, it should be an explicit investigator action

## Planned feature families

Examples:
- blockchain analysis
- OSINT
- cyber/infrastructure
- legal/process
- report-only/output-only

## Contribution buckets

Planned contribution types:
- canonical analysis SQL/views
- analysis-site pages
- analysis-site sources
- report section seed scaffolds/prompts
- report block registrations
- Quarto partials/includes

## Design goal

A future feature should be addable by following a schema and known extension points, not by inventing a custom workflow each time.

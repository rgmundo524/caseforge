# Feature Config Contract

> Status: draft contract

## Purpose

This document defines the canonical YAML config shape for dynamic feature control in a case workspace.

The goals are:
- investigator-editable feature control
- strict schema validation
- grouped settings by investigative domain
- no custom configuration language
- clear separation between build/runtime behavior and authored report tree ownership

## File location

Canonical location:

```text
.caseforge/features.yaml
```

## Example

```yaml
schema_version: 1

features:
  cross-chain-activity:
    enabled: true
    settings:
      defi_swap_matching: true
      matching_mode: aggressive

  urls:
    enabled: true
    settings: {}

outputs:
  analysis_site:
    enabled: true
    include_sections: false
    include_standard_analysis: true
    include_feature_analysis: true

  report_site:
    enabled: true
    include_sections: true
    include_standard_analysis: true
    include_feature_analysis: true

  pdf_report:
    enabled: false
    include_sections: true
    include_standard_analysis: true
    include_feature_analysis: true

policies:
  strict_validation: true
  preserve_authored_sections_on_feature_disable: true
```

## Top-level keys

### `schema_version`
Required integer version.

### `features`
Required mapping of feature ids to feature configuration.

Each feature entry should support:
- `enabled: <bool>`
- `settings: <mapping>`

### `outputs`
Required mapping of output profile ids to output configuration.

### `policies`
Optional mapping of case-level policies.

## Validation rules

Planned validation rules:
- unknown top-level keys should fail in strict mode
- unknown feature ids should fail in strict mode
- feature settings should be validated against feature-specific schemas
- output profile ids should be validated against known profile contracts

## What changes when this file changes

Editing this file after init changes:
- build/runtime behavior
- engine-facing active features
- generated analysis/output behavior
- report profile behavior

Editing this file after init should **not** automatically restructure the canonical report tree in `Sections/`.

Init-selected feature scaffolds are a separate `init-workspace` concern, not an automatic side effect of later config edits.

# Feature Config Contract

> Status: draft contract

## Purpose

This document defines the planned canonical YAML config shape for dynamic feature control in a case workspace.

The goals are:
- investigator-editable feature control
- strict schema validation
- grouped settings by investigative domain
- no custom configuration language

## File location

Planned canonical location:

```text
.caseforge/features.yaml
```

## Example

```yaml
schema_version: 1

features:
  cross_chain:
    enabled: true
    settings:
      defi_swap_matching: true
      matching_mode: aggressive

  urls:
    enabled: true
    settings: {}

  osint:
    enabled: false
    settings:
      resolve_domains: true
      cluster_aliases: true

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

## Default layering

Planned configuration layering:
1. CaseForge defaults
2. template defaults
3. feature defaults
4. workspace feature config
5. output-profile-specific overrides

## Design notes

The schema should feel grouped and discoverable, but remain standard YAML so it works with existing tooling.

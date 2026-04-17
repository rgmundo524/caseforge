# Output Profile Contract

> Status: draft contract

## Purpose

Output profiles define what kind of output is being built from the current case state.

They are different from features:
- a feature describes case capability
- an output profile describes what this build should include and which publishing/UI path it targets

## Initial profiles

### `analysis_site`
Purpose:
- live generated analysis output during an active investigation
- current primary UI path is Evidence

Behavior:
- include report sections: no
- include standard analysis: yes
- include feature analysis: yes
- include generated pages and source queries: yes
- consume canonical analysis outputs

### `report_site`
Purpose:
- narrative/report-oriented HTML output
- target publishing system: Quarto

Behavior:
- include report sections: yes
- include standard analysis: yes
- include feature analysis: selectable/likely yes
- include investigator-authored report structure: yes

### `pdf_report`
Purpose:
- formal PDF report output
- target publishing system: Quarto PDF / Typst-backed Quarto output

Behavior:
- include report sections: yes
- include standard analysis: yes
- include feature analysis: yes

## Planned config shape

```yaml
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
```

## Contract notes

- `analysis_site` must not depend on authored report sections existing
- `report_site` should react to the `Sections/` tree
- `pdf_report` should use the same canonical report tree and computed blocks as `report_site`
- profile behavior should remain deterministic and explicit

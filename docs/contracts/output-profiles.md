# Output Profile Contract

> Status: draft contract

## Purpose

Output profiles define what kind of output is being built from the current case state.

They are different from features:
- a feature describes case capability
- an output profile describes what this build should include

## Initial profiles

### `analysis_site`
Purpose:
- live generated analysis output during an active investigation

Behavior:
- include sections: no
- include standard analysis: yes
- include feature analysis: yes
- include generated pages and source queries: yes

### `report_site`
Purpose:
- narrative/report-oriented website

Behavior:
- include sections: yes
- include standard analysis: yes
- include feature analysis: selectable/likely yes
- include investigator-authored narrative structure: yes

### `pdf_report`
Purpose:
- future PDF report output

Behavior:
- include sections: yes
- include standard analysis: yes
- include feature analysis: yes
- renderer: PDF/LaTeX

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
```

## Contract notes

- `analysis_site` must not depend on authored narrative sections existing
- `report_site` should react to the `Sections/` tree
- profile behavior should remain deterministic and explicit

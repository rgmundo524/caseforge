# Work directory layout (ephemeral)

During a run, the application creates a temporary work directory (e.g., OS temp dir) and uses the following structure.

```
workdir/
  case.yaml

  artifacts/
    figures/
      <figure_id>.<ext>
    chains/
      <chain_id>/
        deposits.csv

  build/
    canonical/
      deposits/
        <chain_id>.csv
    manifest.json
    logs/
      build.log
      validation.json

  report/
    templates/
      sof_notification_v1/
        main.tex
        preamble.tex
        sections/
    generated/
      tables/
        <chain_id>_deposits_bullets.tex
      figures/
        <figure_id>.<ext>     # optional normalized copies
    output/
      sof_notification.pdf
```

## Deletion and output copy rules
- On success:
  - Copy `report/output/sof_notification.pdf` to `--out/sof_notification_<case_number>.pdf`
  - Create `--out/attachments.zip` from `artifacts/` (figures + deposits.csv per chain)
  - Delete workdir unless `--keep-workdir`
- On failure:
  - Delete workdir unless `--keep-workdir`

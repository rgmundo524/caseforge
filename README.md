# caseforge

Caseforge is a reproducible Source of Funds notification generator. It collects structured case metadata and evidentiary artifacts and produces a standardized PDF letter with attachments.

## Ephemeral execution (v1)
- Each run operates in a temporary workdir and does not persist state.
- The workdir is deleted on completion unless `--keep-workdir` is provided.
- Outputs copied to `--out`: the final PDF and an `attachments.zip` containing uploaded figures and normalized deposits CSVs.

## Quick start
1. Enter the development shell:
   ```
   devenv shell
   ```
2. Run the pipeline:
   ```
   just build
   ```

Implementation follows the authoritative specifications in the `spec/` directory.

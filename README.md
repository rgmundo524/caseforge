# CaseForge

CaseForge creates a self-contained Evidence.dev project per case.

Each case directory is a standalone Evidence project backed by a local DuckDB database. CaseForge handles:
- case scaffolding
- raw evidence registration
- SQL-first normalization
- downstream analytical view construction
- Evidence source extraction

## Current Scope

The current primary workflow is the **Default** case template:

> the client was the victim of cryptocurrency theft and the goal is to trace stolen funds.

The project now supports:
- **one primary template per case**
- **zero or more ordered feature overlays**
- a **DuckDB-first, transfer-leg-grain** data pipeline
- Evidence source queries generated from repo templates

Example feature overlays already wired into the project:
- `cross-chain-activity`
- `urls`

## Core Design Decisions

### One case = one Evidence project
A generated case contains its own:
- `data/case.duckdb`
- `pages/`
- `sources/`
- `queries/`
- `evidence.config.yaml`

### Template layering
Case generation now applies layers in this order:

1. `templates/common`
2. `templates/<primary-template>`
3. `templates/features/<feature-1>`
4. `templates/features/<feature-2>`
5. ...

Later layers win on **exact relative-path collisions**.

### Transfer-leg grain
The canonical data grain is now **one row per transfer leg**, not one row per transaction.

That applies to both:
- account-based chains
- UTXO chains

A single `tx_hash` can therefore appear on multiple rows and that is expected.

### SQL-first pipeline
Raw exports are preserved as raw files. CaseForge cleans and interprets them in the normalized/final layers rather than mutating source evidence files.

## Repository Structure

```text
caseforge/                 # Python command + scaffolding logic
templates/common/          # Shared Evidence pages + source query surfaces
templates/default/         # Default theft-tracing template
templates/features/        # Additive feature overlays
templates/sql/             # CaseForge build / normalize SQL
tests/                     # DuckDB smoke tests and helper scripts
tools/CaseForge.py         # CLI entry point
```

## Installation / Prerequisites

From the repo root, commands are run directly with:

```bash
python tools/CaseForge.py <command> ...
```

A generated case also needs:
- DuckDB available on PATH
- Node.js / npm
- `npm install` run inside the generated case before `npm run dev`

## Command Reference

## Create a New Case

```bash
python tools/CaseForge.py new-case \
  --cases-home /path/to/cases-home \
  --case-id 12345 \
  --title "Test Case" \
  --template default \
  --feature cross-chain-activity \
  --feature urls \
  --show-plan
```

### Notes
- `--template` selects the primary case template
- `--feature` is repeatable and adds ordered feature overlays
- `--show-plan` prints the resolved layer order and any path collisions
- generated cases now write `config/caseforge.json` describing the selected template/features

## Register Input Files

`add-files` copies/registers raw evidence files and updates `data/manifest.json`.

### Qlue account (ETH / TRX / similar)
```bash
python tools/CaseForge.py add-files /path/to/Overview-ETH.csv \
  --case-root . \
  --source qlue \
  --model account \
  --blockchain ethereum
```

```bash
python tools/CaseForge.py add-files /path/to/Overview-TRX.csv \
  --case-root . \
  --source qlue \
  --model account \
  --blockchain tron
```

### Qlue UTXO (BTC / similar)
```bash
python tools/CaseForge.py add-files /path/to/Overview-BTC.csv \
  --case-root . \
  --source qlue \
  --model utxo \
  --blockchain bitcoin
```

### TRM
TRM account and TRM UTXO remain supported through the same command family using `--source trm`.

## Normalize

`normalize` reads manifest entries, validates headers, stages each CSV in DuckDB, and recreates:

- `normalized_combined_transactions`
- `v_normalized_transactions`

Run:

```bash
python tools/CaseForge.py normalize --case-root .
```

## Build DB

`build-db` assumes normalization is complete and builds downstream views/tables from `normalized_combined_transactions`.

Run:

```bash
python tools/CaseForge.py build-db --case-root .
```

To also refresh Evidence source extracts:

```bash
python tools/CaseForge.py build-db --case-root . --sources
```

## End-to-End Workflow

```bash
python tools/CaseForge.py new-case \
  --cases-home /path/to/cases-home \
  --case-id 12345 \
  --title "Test Case" \
  --template default \
  --feature cross-chain-activity \
  --feature urls \
  --show-plan

cd /path/to/cases-home/12345_YYYYMMDD_HHMMSS

python /path/to/repo/tools/CaseForge.py add-files /path/to/Overview-ETH.csv \
  --case-root . \
  --source qlue \
  --model account \
  --blockchain ethereum

python /path/to/repo/tools/CaseForge.py add-files /path/to/Overview-TRX.csv \
  --case-root . \
  --source qlue \
  --model account \
  --blockchain tron

python /path/to/repo/tools/CaseForge.py add-files /path/to/Overview-BTC.csv \
  --case-root . \
  --source qlue \
  --model utxo \
  --blockchain bitcoin

python /path/to/repo/tools/CaseForge.py normalize --case-root .
python /path/to/repo/tools/CaseForge.py build-db --case-root . --sources

npm install
npm run dev
```

## Data Pipeline

The current pipeline is:

1. `new-case`
   - scaffold a standalone Evidence project
   - apply `common -> template -> features`
   - write `config/caseforge.json`

2. `add-files`
   - copy raw files into `data/raw/...`
   - update `data/manifest.json`

3. `normalize`
   - build transfer-leg-grain staging tables/views
   - preserve UTXO `direction = in/out`
   - keep account-chain rows with `direction = NULL`

4. `build-db`
   - parse labels
   - assign label entries to the correct leg or side
   - build analytical helper views
   - build final `transactions` view

5. `npm run sources` / `build-db --sources`
   - extract source-query surfaces for Evidence

## Important Tables / Views

### Core
- `normalized_combined_transactions`
- `v_normalized_transactions`
- `v_transfer_base`
- `v_transfers`
- `transactions`

### Label-resolution helpers
- `v_tx_label_entries`
- `v_tx_label_entry_candidates`
- `v_tx_label_entry_resolution`
- `v_tx_label_entry_assignments`
- `v_tx_label_owner_summary`

### Cross-chain helpers
- `v_cross_chain_tx_legs`
- `v_cross_chain_pairs`
- `v_cross_chain_conflicts`

### QA / review
- `v_issue_rows`

### Config
- `v_stablecoins`

## Current Template / Feature Model

### Primary templates
A case selects one primary template, for example:
- `default`

### Feature overlays
Feature overlays are additive capabilities layered on top of the primary template, for example:
- `cross-chain-activity`
- `urls`

Features contribute:
- Evidence pages
- Evidence source queries
- sometimes template-specific README content

Features are intended to be additive by default and should avoid overriding shared/core files unless explicitly required.

## Current Verified Sample-Case Shape

Using the current sample Qlue ETH / TRX / BTC exports, the validated sample case currently shows:

- 15 DuckDB objects used by the test suite
- 57 columns in `transactions`
- 319 transfer rows
- 175 distinct `tx_hash` values
- 141 multi-leg transaction hashes
- 40 distinct theft transaction hashes / theft ids
- zero null core fields
- zero timestamp parsing failures

These numbers are useful as a sanity check while iterating on ingestion and downstream parsing logic.

## Debugging / Testing

### DuckDB smoke tests
The repo includes ordered SQL checks under `tests/database_tests`.

### CSV review exports
The repo also includes helper scripts to export review CSVs for:
- final transactions
- normalized transactions
- label-resolution helpers
- cross-chain helpers
- QA/review views

Those exports are useful when debugging parser behavior or investigating ingestion regressions.

## Known Active Work

The major remaining work is **ingestion/data quality hardening**.

The big architectural changes are already in place:
- transfer-leg-grain normalization
- multi-entry tx-label parsing and assignment
- template + feature overlay generation
- Evidence source-query integration

What still needs focused attention is the correctness and robustness of the data pipeline against messy real-world exports.

Areas to keep watching:
- ingestion regressions after pipeline changes
- label parsing edge cases
- Evidence source-query behavior on empty result sets
- feature pages/query assumptions vs actual extracted data

## Design Philosophy

- One case = one Evidence project
- SQL-first normalization and transforms
- DuckDB-first local workflow
- transfer-leg-grain modeling
- clear separation between:
  - raw intake
  - normalization
  - final analytical build
  - Evidence source extraction
  - page-level presentation

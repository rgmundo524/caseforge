# CaseForge

CaseForge creates a **self-contained Evidence.dev project per case**.

Each case directory is its own standalone Evidence project.

---

# Installation

No installation required yet.

Run commands directly using:

    python tools/CaseForge.py <command> ...

---

# Commands

## Create a New Case

    python tools/CaseForge.py new-case \
      --cases-home /path/to/cases-home \
      --case-id 12343 \
      --title "Avail Holding Ltd"

## Register Input Files

`add-files` only copies/registers raw files + metadata in `data/manifest.json`.

### TRM account

    python tools/CaseForge.py add-files trm.csv --source trm --model account

### TRM UTXO

    python tools/CaseForge.py add-files trm.csv --source trm --model utxo

### Qlue account

    python tools/CaseForge.py add-files qlue_account.csv --source qlue --export-type account --blockchain ethereum

### Qlue UTXO

    python tools/CaseForge.py add-files qlue_utxo.csv --source qlue --export-type utxo --blockchain bitcoin

## Normalize

`normalize` reads manifest entries, validates headers, stages each CSV in DuckDB, runs source-specific SQL templates, and recreates:

- `normalized_combined_transactions`
- `v_normalized_transactions`

Run:

    python tools/CaseForge.py normalize

## Build DB

`build-db` now assumes normalization is complete and only builds downstream case views/tables from `normalized_combined_transactions`.

Run:

    python tools/CaseForge.py build-db

Optional:

    python tools/CaseForge.py build-db --sources

---

# Data Workflow

1. `add-files` (raw file registration)
2. `normalize` (CSV staging + SQL-first normalization)
3. `build-db` (downstream views)
4. `npm run sources` (optional refresh)

---

# Design Philosophy

- One case = one Evidence project
- Reproducible normalization and transforms via SQL files
- DuckDB-first pipeline
- Clear separation between raw intake, normalization, and build

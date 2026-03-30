# CaseForge

CaseForge creates a self-contained Evidence.dev project per case and builds a DuckDB-backed investigation dataset from vendor exports.

Each case directory is its own standalone Evidence project with its own data directory, manifest, normalization layer, downstream build views, and Evidence pages.

## Current workflow

1. Create a new case scaffold
2. Register raw vendor exports in the case manifest
3. Normalize vendor-specific CSVs into `normalized_combined_transactions`
4. Build downstream case views such as `transactions`
5. Refresh Evidence sources when needed

Typical CLI sequence:

```bash
python tools/CaseForge.py new-case --cases-home /path/to/cases-home --case-id 12343 --title "Avail Holding Ltd"
python tools/CaseForge.py add-files <files...>
python tools/CaseForge.py normalize
python tools/CaseForge.py build-db
```

## Commands

### Create a new case

```bash
python tools/CaseForge.py new-case \
  --cases-home /path/to/cases-home \
  --case-id 12343 \
  --title "Avail Holding Ltd"
```

### Register input files

`add-files` copies and registers raw files plus metadata in `data/manifest.json`.

TRM account:

```bash
python tools/CaseForge.py add-files trm.csv --source trm --model account
```

TRM UTXO:

```bash
python tools/CaseForge.py add-files trm.csv --source trm --model utxo
```

Qlue account:

```bash
python tools/CaseForge.py add-files qlue_account.csv --source qlue --export-type account --blockchain ethereum
```

Qlue UTXO:

```bash
python tools/CaseForge.py add-files qlue_utxo.csv --source qlue --export-type utxo --blockchain bitcoin
```

## Data pipeline

### 1. Normalize

`normalize` reads manifest entries, validates headers, stages each CSV in DuckDB, runs source-specific SQL templates, and recreates:

- `normalized_combined_transactions`
- `v_normalized_transactions`

Run:

```bash
python tools/CaseForge.py normalize
```

### 2. Build DB

`build-db` assumes normalization is complete and builds downstream views from `normalized_combined_transactions`.

Run:

```bash
python tools/CaseForge.py build-db
```

Optional:

```bash
python tools/CaseForge.py build-db --sources
```

## Canonical transactions view

The main working surface for analysis and Evidence pages is the `transactions` view.

Current key fields include:

- `vendor`
- `format`
- `chain`
- `ts`
- `tx_hash`
- `from_address`
- `to_address`
- `from_label`
- `to_label`
- `address_label`
- `direction`
- `asset`
- `amount_native`
- `amount_usd`
- `transfer_label`
- `theft_id`
- `stolen_amount_native`
- `stolen_amount_usd`
- `source_file`

### Theft and stolen amount logic

`theft_id` is used to number theft-event rows in chronological order when the transfer label indicates a theft event.

`stolen_amount_native` is intended to represent the traced portion of the client's stolen funds for each row, not just the initial theft row.

Current behavior:

- If `transfer_label` contains a parenthetical numeric override, that value is used
- If no parenthetical value is present, a bare leading numeric value in `transfer_label` is used as a fallback
- If neither is present, the full `amount_native` is used
- The effective stolen value is capped so it cannot exceed the row-level `amount_native`
- `stolen_amount_usd` is scaled proportionally from the same ratio and capped at `amount_usd`

This supports cases where:
- the entire row belongs to the client
- only part of the row belongs to the client
- the label formatting is slightly imperfect but still machine-parseable

### Label cleanup

During build, label fields are cleaned to reduce downstream SQL complexity:

- double quotes are stripped
- repeated whitespace and embedded newlines are collapsed
- leading and trailing whitespace are trimmed

## Testing workflow

Ad hoc SQL checkpoint files can be stored in:

```text
/Blockchain-Nodes/Evidence_Sites/TestQueries
```

Typical one-off usage:

```bash
duckdb case.duckdb -c ".read /Blockchain-Nodes/Evidence_Sites/TestQueries/02_sample_transactions.sql"
```

A Fish helper script can iterate through all test SQL files and dump results to both the terminal and a timestamped report file.

Useful categories of checks include:

- schema inspection
- row counts
- timestamp null checks
- label-pattern matching
- theft numbering validation
- partial stolen-amount validation
- overflow checks
- Service DA / VA / TA / Dormant / Service CXC label tests

## Design philosophy

- one case equals one Evidence project
- DuckDB-first pipeline
- SQL-first normalization and build layers
- clear separation between raw intake, normalization, and downstream views
- reproducible per-case artifacts

## Notes

This project is still evolving quickly. See `TASKS.md` for current cleanup items and backlog work.

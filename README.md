# Proposed README command reference update

## Quick Start

Create a new case:

```bash
python tools/CaseForge.py new-case \
  --cases-home /path/to/cases \
  --case-id 123 \
  --title "Victim Name" \
  --template default \
  --feature cross-chain-activity \
  --feature urls
```

Add evidence files:

```bash
python tools/CaseForge.py add-files /path/to/Overview-ETH.csv \
  --case-root . \
  --source qlue \
  --model account \
  --blockchain ethereum

python tools/CaseForge.py add-files /path/to/Overview-BTC.csv \
  --case-root . \
  --source qlue \
  --model utxo \
  --blockchain bitcoin
```

Normalize the evidence data:

```bash
python tools/CaseForge.py normalize --case-root .
```

Build the analytical database and refresh Evidence source extracts:

```bash
python tools/CaseForge.py build-db --case-root . --run-sources
```

Start the Evidence app:

```bash
npm run dev
```

---

## Template layering model

Each case is generated from filesystem layers:

1. `templates/common`
2. one primary template, such as `templates/default`
3. zero or more feature overlays, such as `templates/features/cross-chain-activity`

Layers are applied in order. Later layers win on exact relative-path collisions.

That means a case can be generated as:

- `common + default`
- `common + default + cross-chain-activity`
- `common + default + urls`
- `common + default + cross-chain-activity + urls`

A case has **one primary template** and **zero or more feature overlays**.

---

## Command reference

### `new-case`

Create a new case directory and scaffold a standalone Evidence project.

```bash
python tools/CaseForge.py new-case \
  --cases-home /path/to/cases \
  --case-id 123 \
  --title "Victim Name" \
  --template default \
  --feature cross-chain-activity \
  --feature urls
```

Key options:
- `--cases-home PATH` — parent directory where cases are created
- `--case-id TEXT` — case identifier used in the generated folder name
- `--title TEXT` — display title for the case
- `--template NAME` — primary template to apply (defaults to `default`)
- `--feature NAME` — repeatable feature overlay flag
- `--list-templates` — list available primary templates and exit
- `--list-features` — list available feature overlays and exit
- `--show-plan` — print the resolved template / feature layer plan
- `--dry-run` — validate inputs and print the plan without creating the case

Notes:
- `common` is always applied first.
- The selected template is applied second.
- Features are applied after that, in the order they are provided.
- The selected template / feature list should be written into case metadata for reproducibility.

### `add-files`

Register one or more raw evidence files with the case and update `data/manifest.json`.

```bash
python tools/CaseForge.py add-files /path/to/file.csv \
  --case-root . \
  --source qlue \
  --model account \
  --blockchain ethereum
```

Key options:
- positional file path(s) — raw evidence files to add
- `--case-root PATH` — target case directory
- `--source NAME` — source / vendor system (for example `qlue` or `trm`)
- `--model NAME` — blockchain model (`account` or `utxo`)
- `--blockchain NAME` — blockchain identifier when required

### `normalize`

Load the registered raw evidence files into the canonical normalized transaction layer in `data/case.duckdb`.

```bash
python tools/CaseForge.py normalize --case-root .
```

Key options:
- `--case-root PATH` — target case directory
- `--duckdb-bin PATH` — optional DuckDB executable path

### `build-db`

Build the final analytical views and optionally refresh Evidence source extracts.

```bash
python tools/CaseForge.py build-db --case-root . --run-sources
```

Key options:
- `--case-root PATH` — target case directory
- `--duckdb-bin PATH` — optional DuckDB executable path
- `--run-sources` — refresh Evidence source extracts after building the DB
- `--sources` — backward-compatible alias for `--run-sources`

Recommended usage:
- Prefer `--run-sources` in docs and examples.
- Keep `--sources` temporarily as a compatibility alias.

---

## Recommended workflow

1. `new-case`
2. `add-files`
3. `normalize`
4. `build-db --run-sources`
5. `npm run dev`

This keeps case composition at creation time and keeps later commands focused on evidence ingestion, normalization, and analysis-build steps.

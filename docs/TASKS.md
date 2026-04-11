# Task

## Project Status

CaseForge has gone through a major architecture shift.

The project is no longer operating on a one-row-per-transaction mental model. The canonical grain is now **one row per transfer leg**, and the generated case is a standalone Evidence project composed from:

- `templates/common`
- one selected primary template
- zero or more ordered feature overlays

This is a real structural change, not just a naming cleanup.

## Current Verified State

### Template / feature system
Implemented and working:
- `new-case --template <name>`
- repeatable `--feature <feature-name>`
- `--show-plan`
- `config/caseforge.json` written into the generated case
- template layering:
  1. common
  2. primary template
  3. feature overlays in order

### Current working example features
- `cross-chain-activity`
- `urls`

### Data pipeline
Implemented:
- raw evidence registration via `add-files`
- transfer-leg-grain normalization
- downstream final `transactions` build
- Evidence source extraction via `build-db --sources`

### Current sample validation snapshot
The current validated sample case (Qlue ETH + TRX + BTC exports) shows:
- 15 DuckDB objects
- `transactions` with 57 columns
- 319 transfer rows
- 175 distinct `tx_hash` values
- 141 multi-leg transaction hashes
- 40 distinct theft transaction hashes / theft ids
- 0 null core fields
- 0 timestamp parsing failures

## Major Design Decisions That Must Not Be Re-litigated

1. **One case = one Evidence project**
   - the generated case is the runnable site

2. **Transfer-leg grain is correct**
   - do not collapse UTXO into one tx row
   - multiple rows per `tx_hash` are expected
   - account-chain rows can also legitimately produce multiple transfer legs per tx

3. **UTXO direction is meaningful**
   - `direction = in` = input UTXO leg
   - `direction = out` = output UTXO leg
   - account-chain rows keep `direction = NULL`

4. **Template composition is layered**
   - common first
   - one primary template second
   - optional feature overlays afterward
   - exact path collisions are resolved by later layer winning

5. **Source-query and page-query layers are distinct**
   - `sources/case/*.sql` = Evidence source queries
   - `queries/*.sql` = reusable page/file queries
   - `pages/*.md` = UI content
   - `templates/sql/*` = CaseForge database-build SQL

6. **Repo-level fixes, not generated-case-only fixes**
   - do not propose fixing only one generated instance when the bug is in the project templates or scaffolding

## What Was Completed Before This Handoff

### Command surface / scaffolding
- `new-case` was extended to understand template selection and feature overlays
- generated cases now show the template layer plan and write `config/caseforge.json`

### Template restructuring
The repo now uses:
- `templates/common`
- `templates/default`
- `templates/features/*`

This replaced the earlier muddier template layout.

### Evidence source surfaces
Shared/common source surfaces exist for:
- `transactions`
- `issue_rows`
- `cross_chain_pairs`
- `cross_chain_conflicts`
- `cross_chain_tx_legs`
- `normalized_transactions`
- `transfer_base`
- tx-label helper views

Default-template source surfaces exist for:
- `deposit_transactions`
- `deposit_exposure_by_service`
- `dormant_asset_locations`
- `theft_transactions`

Feature source surfaces exist for:
- cross-chain activity
- urls

### Label and parsing system
Implemented:
- bracket normalization
- optional label sections
- asset inheritance when value exists but asset does not
- bare numeric traced-value edge case
- multi-entry tx-label parsing for UTXO
- helper views for entry parsing, resolution, assignment, and owner summaries
- transaction-level theft ids
- cross-chain helper surfaces and timing review

## Current Open Problem

### Highest-priority issue
The remaining major work is **ingestion / data-quality correctness**.

The user explicitly wants the next session to focus there.

This means:
- the architecture is good enough to move on
- template/features/Evidence plumbing is mostly in place
- but data coming through the pipeline now has significant quality/correctness issues that need focused debugging

## What the Next Session Should Focus On

1. Reproduce the current ingestion/data-quality issues against the updated repo and current sample exports
2. Inspect:
   - `normalized_combined_transactions`
   - `v_normalized_transactions`
   - `v_transfer_base`
   - `v_transfers`
   - `transactions`
3. Use the helper exports / review CSVs to isolate where corruption or misinterpretation first appears
4. Keep fixes in the repo, not in one generated case
5. Update tests when logic changes in a way that alters the expected semantics

## Debugging Ladder

When something looks wrong, compare in this order:

1. `transactions`
2. `v_transfers`
3. `v_transfer_base`
4. `v_normalized_transactions`
5. `normalized_combined_transactions`

That tells you whether the bug lives in:
- final interpretation / assignment
- intermediate transfer shaping
- normalize-stage ingest

## Evidence Integration Notes

Evidence does not query the source DB live page-by-page in the way the user first expected. The project works by:

1. building `case.duckdb`
2. running source queries under `sources/case/*.sql`
3. extracting those datasets for Evidence
4. pages querying the extracted datasets

So if a page/source issue appears, you need to know whether it is:
- a DuckDB object issue
- a source-query issue
- an extracted-artifact issue
- a page query/UI issue

## Operational Notes for the Next Agent

- Do not assume a proposed flag exists; verify against the actual repo state
- Do not suggest editing only the generated case when the root cause is in the repo
- Provide **full replacement files by path** when asked, not snippets, unless the user explicitly wants snippets
- Be careful to distinguish:
  - current repo state
  - proposed design
  - generated-case behavior

## Concrete Repro Flow

```bash
python tools/CaseForge.py new-case \
  --cases-home . \
  --case-id 03 \
  --title "Test Case" \
  --template default \
  --feature cross-chain-activity \
  --feature urls \
  --show-plan

python tools/CaseForge.py add-files /path/to/Overview-ETH.csv \
  --case-root . \
  --source qlue \
  --model account \
  --blockchain ethereum

python tools/CaseForge.py add-files /path/to/Overview-TRX.csv \
  --case-root . \
  --source qlue \
  --model account \
  --blockchain tron

python tools/CaseForge.py add-files /path/to/Overview-BTC.csv \
  --case-root . \
  --source qlue \
  --model utxo \
  --blockchain bitcoin

python tools/CaseForge.py normalize --case-root .
python tools/CaseForge.py build-db --case-root . --sources

npm install
npm run dev
```

## Short-Term Deliverables For Next Session

1. isolate the current ingestion/data-quality bug(s)
2. identify the first layer where the bad data appears
3. fix it in repo code/templates
4. rerun the SQL tests
5. rerun the CSV export review
6. update README / Task as needed if the pipeline semantics change again

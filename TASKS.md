# CaseForge Tasks

## Current priorities

- Normalize service naming variants so grouping does not fragment totals
  - Example variants such as `Near Intents CxC`, `Near-intents CXC`, and `Near-Intents CxC`
- Strip quotes from address fields in the build layer
  - `from_address`
  - `to_address`
- Decide whether to backfill missing USD values for rows where `amount_usd` is null
- Keep refining label conventions so fewer rows rely on fallback parsing

## Pipeline cleanup

- Review whether `address_label` should remain a placeholder or be populated meaningfully
- Decide whether some label cleanup should happen earlier in normalization rather than only in the build layer
- Standardize casing for chains and service labels where appropriate
- Revisit whether additional canonical views should be added for:
  - Service Deposit Address rows
  - Service Cross-Chain rows
  - Victim Address rows
  - Theft Address rows
  - Dormant rows

## Testing backlog

- Keep the SQL checkpoint suite aligned with the current schema as fields evolve
- Add QA tests for sloppy but parseable labels
- Add tests for service-name normalization once a canonical mapping exists
- Add tests for address cleanup once quotes are stripped from addresses
- Continue separating tests by semantic role rather than mixing different label fields in one query

## Documentation

- Keep `README.md` updated as the pipeline evolves
- Add a short examples section showing a real case directory layout
- Add a short troubleshooting section for common build and test failures
- Document the current meaning of:
  - `theft_id`
  - `stolen_amount_native`
  - `stolen_amount_usd`

## Future enhancements

- Service-name canonicalization table or mapping layer
- Optional pricing/backfill step for rows with missing USD values
- More structured investigator QA reports
- Additional downstream views tailored for Evidence pages and reporting

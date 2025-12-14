# Rendering rules (v1)

## Deposit details
- Always bullet lists (no tables in v1).
- Render only for chains in `chains_in_scope`.

Bullet fields:
- Date: <Time> (passthrough)
- Tx: <hyperlinked tx hash if tx template exists>
- Value: <amount> <symbol> plus USD only if usd_value > 0
- Deposit Address: <hyperlinked address if address template exists>

## Figures
- Render in the order listed in `case.yaml.figures[]`.
- Caption is required.
- If explanation is provided, render it immediately after the figure.
- Orientation:
  - portrait: normal figure inclusion
  - landscape: rotate page using a landscape environment (e.g., pdflscape)

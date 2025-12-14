# Deposits CSV parsing (v1)

Each deposit chain in `chains_in_scope` requires:
- `artifacts/chains/<chain_id>/deposits.csv`

Schema differs by accounting model.

## UTXO accounting model

Required columns:
- Time
- Transaction Label
- Transaction Hash
- Address Label
- Address Hash
- Crypto Value
- USD
- Direction

Parsing rules:
- Crypto Value is `<amount> <symbol>` (two tokens only)
  - Trim whitespace
  - Split on whitespace
  - Token 1: amount
  - Token 2: symbol
  - If more than 2 tokens: hard error
- Transaction Hash => tx hash
- Address Hash => deposit address
- USD parsing:
  - Blank, N/A, -, or missing => 0
  - Strip `$`, commas, parentheses
  - Negative USD not allowed (hard error)
  - Render USD only if > 0

## Account accounting model

Required columns:
- Time
- Transfer Label
- Transaction
- Source Address Label
- Source Address Hash
- Recipient Address Label
- Recipient Address Hash
- Crypto Value
- Crypto Asset
- USD

Parsing rules:
- Crypto Value => amount (numeric)
- Crypto Asset => symbol
- Transaction => tx hash
- Recipient Address Hash => deposit address
- USD parsing rules same as above

## Normalized canonical CSV schema
Write `build/canonical/deposits/<chain_id>.csv` with:
- time
- tx_hash
- deposit_address
- amount
- symbol
- usd_value

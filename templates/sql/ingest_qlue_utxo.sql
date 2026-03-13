-- Ingest Qlue UTXO exports (BTC-style)
-- Assumes files exist under: data/raw/qlue/*btc*.csv
-- Direction semantics (per your clarification):
--   out = tx output (address receives funds)
--   in  = tx input  (address spent funds into tx)

CREATE OR REPLACE TABLE raw_qlue_utxo AS
SELECT
  *,
  filename AS source_file
FROM read_csv_auto(
  'data/raw/qlue/*btc*.csv',
  header=true,
  filename=true,
  union_by_name=true
);

CREATE OR REPLACE VIEW v_map_qlue_utxo AS
WITH base AS (
  SELECT
    'qlue' AS vendor,
    'qlue_utxo' AS format,
    lower(Direction) AS direction,

    'bitcoin' AS chain,

    -- Common format: 2025-12-01 02:44:59
    coalesce(
      try_strptime(Time, '%Y-%m-%d %H:%M:%S'),
      try_strptime(Time, '%Y-%m-%d %H:%M:%S%z')
    ) AS ts,

    "Transaction Hash" AS tx_hash,

    CASE WHEN lower(Direction) = 'in'  THEN "Address Hash" ELSE NULL END AS from_address,
    CASE WHEN lower(Direction) = 'out' THEN "Address Hash" ELSE NULL END AS to_address,

    NULL::VARCHAR AS from_label,
    NULL::VARCHAR AS to_label,

    "Address Label" AS address_label,
    "Transaction Label" AS transfer_label,

    regexp_extract("Crypto Value", '^\\s*([0-9]*\\.?[0-9]+)', 1) AS amount_token,
    upper(regexp_extract("Crypto Value", '([A-Za-z0-9]+)\\s*$', 1)) AS asset,

    try_cast(USD AS DOUBLE) AS amount_usd,

    source_file
  FROM raw_qlue_utxo
),
typed AS (
  SELECT
    *,
    try_cast(amount_token AS DOUBLE) AS amount_native
  FROM base
),
usd_fixed AS (
  SELECT
    *,
    CASE
      WHEN amount_usd IS NULL AND asset IN (SELECT asset FROM v_stablecoins) THEN amount_native
      ELSE amount_usd
    END AS amount_usd_fixed
  FROM typed
),
stolen AS (
  SELECT
    *,
    regexp_extract(transfer_label, '#(\\d+)', 1) AS theft_id_str,
    regexp_extract(transfer_label, '([0-9][0-9,]*\\.?[0-9]*)\\s*$', 1) AS stolen_token
  FROM usd_fixed
)
SELECT
  vendor, format, chain, ts, tx_hash,
  from_address, to_address,
  from_label, to_label,
  address_label,
  direction,
  asset,
  amount_native,
  amount_usd_fixed AS amount_usd,
  transfer_label,
  try_cast(theft_id_str AS INTEGER) AS theft_id,

  CASE
    WHEN stolen_token IS NULL OR stolen_token = '' THEN amount_native
    ELSE try_cast(replace(stolen_token, ',', '') AS DOUBLE)
  END AS stolen_amount_native,

  CASE
    WHEN amount_usd_fixed IS NULL THEN NULL
    WHEN amount_native IS NULL OR amount_native = 0 THEN amount_usd_fixed
    ELSE amount_usd_fixed * (
      (CASE
        WHEN stolen_token IS NULL OR stolen_token = '' THEN amount_native
        ELSE try_cast(replace(stolen_token, ',', '') AS DOUBLE)
      END) / amount_native
    )
  END AS stolen_amount_usd,

  source_file
FROM stolen;


-- Ingest Qlue account-based exports (ETH/TRX/etc.)
-- Assumes files exist under: data/raw/qlue/*.csv

CREATE OR REPLACE TABLE raw_qlue_account AS
SELECT
  *,
  filename AS source_file
FROM read_csv_auto(
  'data/raw/qlue/*.csv',
  header=true,
  filename=true,
  union_by_name=true
)
-- Qlue account exports have these columns; this filters out non-account exports if mixed.
WHERE "Transaction" IS NOT NULL AND "Crypto Asset" IS NOT NULL AND "Recipient Address Hash" IS NOT NULL;

-- Normalize Qlue account into canonical shape.
-- Fix: DuckDB strptime does not support %e, so we pad single-digit day values before parsing.
CREATE OR REPLACE VIEW v_map_qlue_account AS
WITH base AS (
  SELECT
    'qlue' AS vendor,
    'qlue_account' AS format,
    NULL::VARCHAR AS direction,

    CASE
      WHEN lower(source_file) LIKE '%eth%' THEN 'ethereum'
      WHEN lower(source_file) LIKE '%trx%' THEN 'tron'
      ELSE NULL
    END AS chain,

    try_strptime(
      regexp_replace(
        replace(Time, ' GMT+0', ''),
        '^(\\w+)\\s+(\\d)\\s',
        '\\1 0\\2 '
      ),
      '%B %d %Y %I:%M:%S %p'
    ) AS ts,

    Transaction AS tx_hash,

    replace("Source Address Hash", '"', '') AS from_address,
    replace("Recipient Address Hash", '"', '') AS to_address,

    -- IMPORTANT: Qlue labels often include quotes and stray whitespace/newlines.
    -- Clean them here so downstream logic can rely on consistent strings.
    nullif(trim(replace("Source Address Label", '"', '')), '') AS from_label,
    nullif(trim(replace("Recipient Address Label", '"', '')), '') AS to_label,

    NULL::VARCHAR AS address_label,

    "Transfer Label" AS transfer_label,

    upper("Crypto Asset") AS asset,
    try_cast("Crypto Value" AS DOUBLE) AS amount_native,
    try_cast(USD AS DOUBLE) AS amount_usd,

    source_file
  FROM raw_qlue_account
),
usd_fixed AS (
  SELECT
    *,
    CASE
      WHEN amount_usd IS NULL AND asset IN (SELECT asset FROM v_stablecoins) THEN amount_native
      ELSE amount_usd
    END AS amount_usd_fixed
  FROM base
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


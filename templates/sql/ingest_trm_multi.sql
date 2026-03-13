-- Ingest TRM multi-chain exports
-- Assumes files exist under: data/raw/trm/*.csv
-- Uses:
--   Type='address' rows to map Address -> Name (label)
--   Type='transfer' rows for transfer events
-- Uses Notes column as transfer label (your theft attribution label)

CREATE OR REPLACE TABLE raw_trm AS
SELECT
  *,
  filename AS source_file
FROM read_csv_auto(
  'data/raw/trm/*.csv',
  header=true,
  filename=true,
  union_by_name=true
);

CREATE OR REPLACE VIEW v_map_trm AS
WITH addr_map AS (
  SELECT
    Address AS address,
    Name AS label
  FROM raw_trm
  WHERE lower(Type) = 'address'
),
xfer AS (
  SELECT
    'trm' AS vendor,
    'trm_multi' AS format,
    NULL::VARCHAR AS direction,

    lower(Chain) AS chain,

    -- Timestamp can be auto-typed by DuckDB. Handle both typed and string cases.
    coalesce(
      try_cast(Timestamp AS TIMESTAMP),
      try_strptime(cast(Timestamp AS VARCHAR), '%Y-%m-%d %H:%M:%SZ')
    ) AS ts,

    "Txn Hash" AS tx_hash,

    "From" AS from_address,
    "To" AS to_address,

    (SELECT label FROM addr_map m WHERE m.address = raw_trm."From" LIMIT 1) AS from_label,
    (SELECT label FROM addr_map m WHERE m.address = raw_trm."To" LIMIT 1) AS to_label,

    NULL::VARCHAR AS address_label,

    Notes AS transfer_label,

    upper(Asset) AS asset,
    try_cast(Value AS DOUBLE) AS amount_native,
    try_cast("Value USD" AS DOUBLE) AS amount_usd,

    source_file
  FROM raw_trm
  WHERE lower(Type) = 'transfer'
),
usd_fixed AS (
  SELECT
    *,
    CASE
      WHEN amount_usd IS NULL AND asset IN (SELECT asset FROM v_stablecoins) THEN amount_native
      ELSE amount_usd
    END AS amount_usd_fixed
  FROM xfer
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


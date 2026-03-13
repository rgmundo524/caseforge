PRAGMA threads=4;

-- =========================
-- Constants
-- =========================

-- Stablecoin tickers for USD fill when USD is missing.
CREATE OR REPLACE TEMP VIEW v_stablecoins AS
SELECT * FROM (VALUES
  ('USDT'),('USDC'),('USDM'),('RUSD'),('DAI'),('TUSD'),('FDUSD'),('USDP'),
  ('GUSD'),('LUSD'),('PYUSD'),('USDE'),('FRAX')
) AS t(asset);

-- Helper: parse the last numeric token in a label (commas allowed).
-- Example labels:
--   "#1 25,000"
--   "#1 Deposit (OKX) 25,000"
-- If no numeric token exists, returns NULL.
CREATE OR REPLACE TEMP VIEW v_label_parse_demo AS
SELECT
  NULL::VARCHAR AS label,
  NULL::VARCHAR AS stolen_token
WHERE FALSE;

-- =========================
-- Raw ingestion
-- =========================

-- Qlue account-based exports live here. We ingest all CSVs and rely on header matching.
-- Expected columns include:
-- Time, Transfer Label, Transaction, Source Address Label, Source Address Hash,
-- Recipient Address Label, Recipient Address Hash, Crypto Value, Crypto Asset, USD, ...
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
WHERE
  -- identify qlue_account by the presence of these columns
  "Transfer Label" IS NOT NULL
  AND "Crypto Asset" IS NOT NULL
  AND "Recipient Address Hash" IS NOT NULL;

-- Qlue UTXO exports live here (e.g., Overview-BTC.csv).
-- Expected columns include:
-- Time, Transaction Label, Transaction Hash, Address Label, Address Hash, Crypto Value, USD, Direction
CREATE OR REPLACE TABLE raw_qlue_utxo AS
SELECT
  *,
  filename AS source_file
FROM read_csv_auto(
  'data/raw/qlue/*.csv',
  header=true,
  filename=true,
  union_by_name=true
)
WHERE
  "Transaction Hash" IS NOT NULL
  AND "Direction" IS NOT NULL
  AND "Address Hash" IS NOT NULL
  AND "Transaction Label" IS NOT NULL;

-- TRM export(s) live here.
-- Expected columns include: Type, Chain, Address, Name, Txn Hash, Timestamp, From, To, Asset, Value, Value USD, Notes
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

-- =========================
-- Normalization helpers
-- =========================

-- Qlue account: normalize columns and stolen attribution.
CREATE OR REPLACE VIEW v_map_qlue_account AS
WITH base AS (
  SELECT
    'qlue' AS vendor,
    'qlue_account' AS format,
    NULL::VARCHAR AS direction,

    -- Chain inference: if you want, later we can pass chain via manifest and join it in.
    -- For now, infer from source filename if possible.
    CASE
      WHEN lower(source_file) LIKE '%eth%' THEN 'ethereum'
      WHEN lower(source_file) LIKE '%trx%' THEN 'tron'
      ELSE NULL
    END AS chain,

    try_strptime(replace(Time, ' GMT+0', ''), '%B %e %Y %I:%M:%S %p') AS ts,
    Transaction AS tx_hash,

    replace("Source Address Hash", '"', '') AS from_address,
    replace("Recipient Address Hash", '"', '') AS to_address,

    "Source Address Label" AS from_label,
    "Recipient Address Label" AS to_label,

    "Transfer Label" AS transfer_label,

    "Crypto Asset" AS asset,
    "Crypto Value"::DOUBLE AS amount_native,

    -- USD may be blank; keep as NULL for now, fill below
    try_cast(USD AS DOUBLE) AS amount_usd,

    source_file
  FROM raw_qlue_account
),
usd_fixed AS (
  SELECT
    *,
    CASE
      WHEN amount_usd IS NULL AND upper(asset) IN (SELECT asset FROM v_stablecoins) THEN amount_native
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
  NULL::VARCHAR AS address_label,
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

-- Qlue UTXO: parse "Crypto Value" which includes ticker, and use Direction:
-- out = outputs of the tx (received at address)
-- in  = inputs spent by the tx
CREATE OR REPLACE VIEW v_map_qlue_utxo AS
WITH base AS (
  SELECT
    'qlue' AS vendor,
    'qlue_utxo' AS format,
    lower(Direction) AS direction,

    CASE
      WHEN lower(source_file) LIKE '%btc%' THEN 'bitcoin'
      ELSE NULL
    END AS chain,

    -- UTXO time formatting in your file appears like: "2025-12-01 02:44:59"
    -- If it differs, adjust here.
    try_strptime(Time, '%Y-%m-%d %H:%M:%S') AS ts,

    "Transaction Hash" AS tx_hash,

    CASE WHEN lower(Direction) = 'in'  THEN "Address Hash" ELSE NULL END AS from_address,
    CASE WHEN lower(Direction) = 'out' THEN "Address Hash" ELSE NULL END AS to_address,

    NULL::VARCHAR AS from_label,
    NULL::VARCHAR AS to_label,

    "Address Label" AS address_label,
    "Transaction Label" AS transfer_label,

    -- Crypto Value includes ticker like "0.8743894 BTC"
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

-- TRM: build an address->label map from Type='address', then join into transfer rows.
-- Notes column is used as the transaction label.
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

    Chain AS chain,
    try_strptime(Timestamp, '%Y-%m-%d %H:%M:%SZ') AS ts,
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

-- =========================
-- Canonical union
-- =========================

CREATE OR REPLACE VIEW v_transfers AS
SELECT * FROM v_map_qlue_account
UNION ALL
SELECT * FROM v_map_qlue_utxo
UNION ALL
SELECT * FROM v_map_trm;

-- =========================
-- Exposure by service and asset (first objective)
-- =========================

-- Extract service name from "Deposit Address (OKX)"
CREATE OR REPLACE VIEW v_exposure_by_service_asset AS
WITH deposits AS (
  -- Account-based: recipient label is the deposit address label
  SELECT
    regexp_extract(to_label, 'Deposit Address \\((.*?)\\)', 1) AS service,
    asset,
    amount_native,
    amount_usd,
    stolen_amount_native,
    stolen_amount_usd
  FROM v_transfers
  WHERE
    format = 'qlue_account'
    AND to_label LIKE 'Deposit Address (%'

  UNION ALL

  -- UTXO: outputs to the deposit address label are "received"
  SELECT
    regexp_extract(address_label, 'Deposit Address \\((.*?)\\)', 1) AS service,
    asset,
    amount_native,
    amount_usd,
    stolen_amount_native,
    stolen_amount_usd
  FROM v_transfers
  WHERE
    format = 'qlue_utxo'
    AND lower(direction) = 'out'
    AND address_label LIKE 'Deposit Address (%'

  UNION ALL

  -- TRM: to_label derived from address map
  SELECT
    regexp_extract(to_label, 'Deposit Address \\((.*?)\\)', 1) AS service,
    asset,
    amount_native,
    amount_usd,
    stolen_amount_native,
    stolen_amount_usd
  FROM v_transfers
  WHERE
    format = 'trm_multi'
    AND to_label LIKE 'Deposit Address (%'
)
SELECT
  service,
  asset,
  count(*) AS tx_count,
  sum(amount_native) AS gross_amount_native,
  sum(stolen_amount_native) AS stolen_amount_native,
  sum(amount_usd) AS gross_amount_usd,
  sum(stolen_amount_usd) AS stolen_amount_usd
FROM deposits
WHERE service IS NOT NULL AND service <> ''
GROUP BY 1,2
ORDER BY stolen_amount_usd DESC NULLS LAST, stolen_amount_native DESC;

-- =========================
-- Daily flows (useful for timelines)
-- =========================
CREATE OR REPLACE VIEW v_daily_flows AS
SELECT
  chain,
  date_trunc('day', ts) AS day,
  asset,
  count(*) AS tx_count,
  sum(amount_usd) AS gross_usd,
  sum(stolen_amount_usd) AS stolen_usd
FROM v_transfers
WHERE ts IS NOT NULL
GROUP BY 1,2,3
ORDER BY day;


PRAGMA threads=4;

CREATE OR REPLACE VIEW v_stablecoins AS
SELECT * FROM (VALUES
  ('USDT'),('USDC'),('USDM'),('RUSD'),('DAI'),('TUSD'),('FDUSD'),('USDP'),
  ('GUSD'),('LUSD'),('PYUSD'),('USDE'),('FRAX')
) AS t(asset);

CREATE OR REPLACE VIEW v_transfers AS
WITH base AS (
  SELECT
    vendor,
    CASE
      WHEN vendor = 'trm' AND tx_model = 'account' THEN 'trm'
      WHEN vendor = 'trm' AND tx_model = 'utxo' THEN 'trm'
      WHEN vendor = 'qlue' AND tx_model = 'account' THEN 'qlue_account'
      WHEN vendor = 'qlue' AND tx_model = 'utxo' THEN 'qlue_utxo'
      ELSE vendor || '_' || tx_model
    END AS format,
    blockchain AS chain,
    time AS ts,
    tx AS tx_hash,
    source_address AS from_address,
    destination_address AS to_address,
    nullif(trim(regexp_replace(replace(coalesce(source_label, ''), '"', ''), '\s+', ' ', 'g')), '') AS from_label,
    nullif(trim(regexp_replace(replace(coalesce(destination_label, ''), '"', ''), '\s+', ' ', 'g')), '') AS to_label,
    NULL::VARCHAR AS address_label,
    CASE WHEN tx_model = 'utxo' THEN 'utxo' ELSE NULL END AS direction,
    upper(asset) AS asset,
    value AS amount_native,
    usd AS amount_usd,
    nullif(trim(regexp_replace(replace(coalesce(tx_label, ''), '"', ''), '\s+', ' ', 'g')), '') AS transfer_label,
    source_file,

    CASE
      WHEN lower(coalesce(tx_label, '')) LIKE '%theft%' THEN 1
      ELSE 0
    END AS is_theft_tx,

    try_cast(
      replace(
        regexp_extract(
          trim(regexp_replace(replace(coalesce(tx_label, ''), '"', ''), '\s+', ' ', 'g')),
          '\(([-+]?(?:[0-9][0-9,]*(\.[0-9]+)?|\.[0-9]+))',
          1
        ),
        ',',
        ''
      ) AS DOUBLE
    ) AS parsed_paren_stolen_amount_native,

    try_cast(
      replace(
        regexp_extract(
          trim(regexp_replace(replace(coalesce(tx_label, ''), '"', ''), '\s+', ' ', 'g')),
          '^[-+]?(?:[0-9][0-9,]*(\.[0-9]+)?|\.[0-9]+)',
          0
        ),
        ',',
        ''
      ) AS DOUBLE
    ) AS parsed_bare_stolen_amount_native
  FROM normalized_combined_transactions
),
numbered AS (
  SELECT
    *,
    CASE
      WHEN is_theft_tx = 1 THEN CAST(
        sum(is_theft_tx) OVER (
          ORDER BY ts NULLS LAST, tx_hash, source_file
          ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS INTEGER
      )
      ELSE NULL
    END AS theft_id
  FROM base
)
SELECT
  vendor,
  format,
  chain,
  ts,
  tx_hash,
  from_address,
  to_address,
  from_label,
  to_label,
  address_label,
  direction,
  asset,
  amount_native,
  amount_usd,
  transfer_label,
  theft_id,
  CASE
    WHEN amount_native IS NULL THEN coalesce(parsed_paren_stolen_amount_native, parsed_bare_stolen_amount_native)
    ELSE LEAST(
      amount_native,
      coalesce(parsed_paren_stolen_amount_native, parsed_bare_stolen_amount_native, amount_native)
    )
  END AS stolen_amount_native,
  CASE
    WHEN amount_native IS NULL OR amount_usd IS NULL THEN NULL
    WHEN amount_native = 0 THEN NULL
    ELSE LEAST(
      amount_usd,
      amount_usd * (
        CASE
          WHEN amount_native IS NULL THEN coalesce(parsed_paren_stolen_amount_native, parsed_bare_stolen_amount_native)
          ELSE LEAST(
            amount_native,
            coalesce(parsed_paren_stolen_amount_native, parsed_bare_stolen_amount_native, amount_native)
          )
        END / amount_native
      )
    )
  END AS stolen_amount_usd,
  source_file
FROM numbered;

CREATE OR REPLACE VIEW transactions AS
SELECT * FROM v_transfers;

CREATE OR REPLACE VIEW v_normalized_transactions AS
SELECT * FROM normalized_combined_transactions;

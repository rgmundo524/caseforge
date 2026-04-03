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
    source_file
  FROM normalized_combined_transactions
),
parsed AS (
  SELECT
    *,
    trim(coalesce(transfer_label, '')) AS transfer_label_clean,
    trim(coalesce(from_label, '')) AS from_label_clean,
    trim(coalesce(to_label, '')) AS to_label_clean,

    NULLIF(trim(regexp_extract(trim(coalesce(transfer_label, '')), '^\[([^\]]+)\]', 1)), '') AS tx_actions,
    NULLIF(trim(regexp_extract(trim(coalesce(from_label, '')), '^\[([^\]]+)\]', 1)), '') AS from_types,
    NULLIF(trim(regexp_extract(trim(coalesce(to_label, '')), '^\[([^\]]+)\]', 1)), '') AS to_types,

    NULLIF(
      trim(
        regexp_replace(
          trim(regexp_replace(trim(coalesce(transfer_label, '')), '^\[[^\]]+\]\s*', '')),
          '\s*\([^)]*\)\s*$',
          ''
        )
      ),
      ''
    ) AS tx_counterparty,

    NULLIF(
      trim(
        regexp_replace(
          trim(regexp_replace(trim(coalesce(from_label, '')), '^\[[^\]]+\]\s*', '')),
          '\s*\([^)]*\)\s*$',
          ''
        )
      ),
      ''
    ) AS from_counterparty,

    NULLIF(
      trim(
        regexp_replace(
          trim(regexp_replace(trim(coalesce(to_label, '')), '^\[[^\]]+\]\s*', '')),
          '\s*\([^)]*\)\s*$',
          ''
        )
      ),
      ''
    ) AS to_counterparty,

    try_cast(
      replace(
        regexp_extract(
          trim(coalesce(transfer_label, '')),
          '\(([-+]?(?:[0-9][0-9,]*(?:\.[0-9]+)?|\.[0-9]+))\s+[A-Za-z0-9._-]+\)',
          1
        ),
        ',',
        ''
      ) AS DOUBLE
    ) AS tx_traced_value_native,

    upper(
      NULLIF(
        trim(
          regexp_extract(
            trim(coalesce(transfer_label, '')),
            '\((?:[-+]?(?:[0-9][0-9,]*(?:\.[0-9]+)?|\.[0-9]+))\s+([A-Za-z0-9._-]+)\)',
            1
          )
        ),
        ''
      )
    ) AS tx_traced_value_asset,

    try_cast(
      replace(
        regexp_extract(
          trim(coalesce(from_label, '')),
          '\(([-+]?(?:[0-9][0-9,]*(?:\.[0-9]+)?|\.[0-9]+))\s+[A-Za-z0-9._-]+\)',
          1
        ),
        ',',
        ''
      ) AS DOUBLE
    ) AS from_dormant_value_native,

    upper(
      NULLIF(
        trim(
          regexp_extract(
            trim(coalesce(from_label, '')),
            '\((?:[-+]?(?:[0-9][0-9,]*(?:\.[0-9]+)?|\.[0-9]+))\s+([A-Za-z0-9._-]+)\)',
            1
          )
        ),
        ''
      )
    ) AS from_dormant_value_asset,

    try_cast(
      replace(
        regexp_extract(
          trim(coalesce(to_label, '')),
          '\(([-+]?(?:[0-9][0-9,]*(?:\.[0-9]+)?|\.[0-9]+))\s+[A-Za-z0-9._-]+\)',
          1
        ),
        ',',
        ''
      ) AS DOUBLE
    ) AS to_dormant_value_native,

    upper(
      NULLIF(
        trim(
          regexp_extract(
            trim(coalesce(to_label, '')),
            '\((?:[-+]?(?:[0-9][0-9,]*(?:\.[0-9]+)?|\.[0-9]+))\s+([A-Za-z0-9._-]+)\)',
            1
          )
        ),
        ''
      )
    ) AS to_dormant_value_asset
  FROM base
),
numbered AS (
  SELECT
    *,
    CASE
      WHEN lower(coalesce(tx_actions, '')) LIKE '%theft%' THEN CAST(
        sum(
          CASE WHEN lower(coalesce(tx_actions, '')) LIKE '%theft%' THEN 1 ELSE 0 END
        ) OVER (
          ORDER BY ts NULLS LAST, tx_hash, source_file
          ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS INTEGER
      )
      ELSE NULL
    END AS theft_id
  FROM parsed
),
valued AS (
  SELECT
    *,
    CASE
      WHEN amount_native IS NULL THEN coalesce(tx_traced_value_native, amount_native)
      ELSE LEAST(amount_native, coalesce(tx_traced_value_native, amount_native))
    END AS stolen_amount_native
  FROM numbered
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
  stolen_amount_native,
  CASE
    WHEN amount_native IS NULL OR amount_usd IS NULL OR amount_native = 0 THEN NULL
    ELSE LEAST(amount_usd, amount_usd * (stolen_amount_native / amount_native))
  END AS stolen_amount_usd,
  source_file,
  tx_actions,
  tx_counterparty,
  tx_traced_value_native,
  coalesce(tx_traced_value_asset, asset) AS tx_traced_value_asset,
  from_types,
  from_counterparty,
  from_dormant_value_native,
  from_dormant_value_asset,
  to_types,
  to_counterparty,
  to_dormant_value_native,
  to_dormant_value_asset
FROM valued;

CREATE OR REPLACE VIEW transactions AS
SELECT * FROM v_transfers;

CREATE OR REPLACE VIEW v_normalized_transactions AS
SELECT * FROM normalized_combined_transactions;

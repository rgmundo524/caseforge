CREATE OR REPLACE TEMP VIEW norm_{{FILE_ID}} AS
WITH base AS (
  SELECT
    'qlue' AS vendor,
    'utxo' AS tx_model,
    '{{SOURCE_FILE}}' AS source_file,
    '{{BLOCKCHAIN}}' AS blockchain,
    NULLIF(trim(cast("Time" AS VARCHAR)), '') AS time_raw,
    NULLIF(trim(cast("Transaction Hash" AS VARCHAR)), '') AS tx,
    NULLIF(trim(regexp_replace(replace(coalesce(cast("Transaction Label" AS VARCHAR), ''), '"', ''), '\s+', ' ', 'g')), '') AS tx_label,
    CASE
      WHEN lower(trim(cast("Direction" AS VARCHAR))) IN ('in', 'input', 'incoming') THEN 'in'
      WHEN lower(trim(cast("Direction" AS VARCHAR))) IN ('out', 'output', 'outgoing') THEN 'out'
      ELSE NULL
    END AS direction,
    NULLIF(trim(cast("Address Hash" AS VARCHAR)), '') AS address_hash,
    NULLIF(trim(regexp_replace(replace(coalesce(cast("Address Label" AS VARCHAR), ''), '"', ''), '\s+', ' ', 'g')), '') AS address_label,
    NULLIF(trim(cast("Source Group" AS VARCHAR)), '') AS source_group_raw,
    NULLIF(trim(cast("Source Group Description" AS VARCHAR)), '') AS source_group_description_raw,
    NULLIF(trim(cast("Recipient Group" AS VARCHAR)), '') AS recipient_group_raw,
    NULLIF(trim(cast("Recipient Group Description" AS VARCHAR)), '') AS recipient_group_description_raw,
    upper(NULLIF(trim(cast("Token Policy" AS VARCHAR)), '')) AS token_policy,
    NULLIF(trim(cast("Crypto Value" AS VARCHAR)), '') AS crypto_value_raw,
    try_cast(
      replace(
        regexp_extract(
          NULLIF(trim(cast("Crypto Value" AS VARCHAR)), ''),
          '([-+]?(?:[0-9][0-9,]*(?:\.[0-9]+)?|\.[0-9]+))',
          1
        ),
        ',',
        ''
      ) AS DOUBLE
    ) AS row_value,
    upper(
      NULLIF(
        trim(
          regexp_replace(
            regexp_replace(
              NULLIF(trim(cast("Crypto Value" AS VARCHAR)), ''),
              '^\s*[-+]?(?:[0-9][0-9,]*(?:\.[0-9]+)?|\.[0-9]+)\s*',
              ''
            ),
            '\s+',
            ' '
          )
        ),
        ''
      )
    ) AS row_asset,
    try_cast(replace(replace(NULLIF(trim(cast("USD" AS VARCHAR)), ''), ',', ''), '$', '') AS DOUBLE) AS usd_raw
  FROM {{RAW_TABLE}}
  WHERE NULLIF(trim(cast("Transaction Hash" AS VARCHAR)), '') IS NOT NULL
), typed AS (
  SELECT
    *,
    coalesce(
      try_strptime(
        regexp_replace(replace(time_raw, ' GMT+0', ''), '^(\\w+)\\s+(\\d)\\s', '\\1 0\\2 '),
        '%B %d %Y %I:%M:%S %p'
      ),
      try_strptime(
        regexp_replace(replace(time_raw, ' GMT+0', ''), '^(\\w+)\\s+(\\d)\\s', '\\1 0\\2 '),
        '%B %d %Y %H:%M:%S'
      ),
      try_cast(time_raw AS TIMESTAMP)
    ) AS time,
    coalesce(token_policy, row_asset) AS asset_norm,
    CASE
      WHEN usd_raw IS NULL AND coalesce(token_policy, row_asset) IN (SELECT asset FROM v_stablecoins) THEN row_value
      ELSE usd_raw
    END AS usd
  FROM base
)
SELECT
  vendor,
  tx_model,
  source_file,
  blockchain,
  time,
  tx,
  tx_label,
  CASE WHEN direction = 'in'  THEN address_hash  ELSE NULL END AS source_address,
  CASE WHEN direction = 'in'  THEN address_label ELSE NULL END AS source_label,
  CASE WHEN direction = 'in'  THEN source_group_raw ELSE NULL END AS source_group,
  CASE WHEN direction = 'in'  THEN source_group_description_raw ELSE NULL END AS source_group_description,
  CASE WHEN direction = 'out' THEN address_hash  ELSE NULL END AS destination_address,
  CASE WHEN direction = 'out' THEN address_label ELSE NULL END AS destination_label,
  CASE WHEN direction = 'out' THEN recipient_group_raw ELSE NULL END AS destination_group,
  CASE WHEN direction = 'out' THEN recipient_group_description_raw ELSE NULL END AS destination_group_description,
  direction,
  asset_norm AS asset,
  row_value AS value,
  usd
FROM typed;

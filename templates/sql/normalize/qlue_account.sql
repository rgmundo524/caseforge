CREATE OR REPLACE TEMP VIEW norm_{{FILE_ID}} AS
WITH base AS (
  SELECT
    'qlue' AS vendor,
    'account' AS tx_model,
    '{{SOURCE_FILE}}' AS source_file,
    '{{BLOCKCHAIN}}' AS blockchain,
    NULLIF(trim(cast("Time" AS VARCHAR)), '') AS time_raw,
    NULLIF(trim(replace(cast("Transaction" AS VARCHAR), '"', '')), '') AS tx,
    NULLIF(trim(regexp_replace(replace(coalesce(cast("Transfer Label" AS VARCHAR), ''), '"', ''), '\s+', ' ', 'g')), '') AS tx_label,
    NULLIF(trim(replace(cast("Source Address Hash" AS VARCHAR), '"', '')), '') AS source_address,
    NULLIF(trim(regexp_replace(replace(coalesce(cast("Source Address Label" AS VARCHAR), ''), '"', ''), '\s+', ' ', 'g')), '') AS source_label,
    NULLIF(trim(cast("Source Group" AS VARCHAR)), '') AS source_group,
    NULLIF(trim(cast("Source Group Description" AS VARCHAR)), '') AS source_group_description,
    NULLIF(trim(replace(cast("Recipient Address Hash" AS VARCHAR), '"', '')), '') AS destination_address,
    NULLIF(trim(regexp_replace(replace(coalesce(cast("Recipient Address Label" AS VARCHAR), ''), '"', ''), '\s+', ' ', 'g')), '') AS destination_label,
    NULLIF(trim(cast("Recipient Group" AS VARCHAR)), '') AS destination_group,
    NULLIF(trim(cast("Recipient Group Description" AS VARCHAR)), '') AS destination_group_description,
    upper(NULLIF(trim(cast("Crypto Asset" AS VARCHAR)), '')) AS asset,
    try_cast(replace(NULLIF(trim(cast("Crypto Value" AS VARCHAR)), ''), ',', '') AS DOUBLE) AS value,
    try_cast(replace(replace(NULLIF(trim(cast("USD" AS VARCHAR)), ''), ',', ''), '$', '') AS DOUBLE) AS usd_raw
  FROM {{RAW_TABLE}}
  WHERE NULLIF(trim(replace(cast("Transaction" AS VARCHAR), '"', '')), '') IS NOT NULL
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
    ) AS time
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
  source_address,
  source_label,
  source_group,
  source_group_description,
  destination_address,
  destination_label,
  destination_group,
  destination_group_description,
  NULL::VARCHAR AS direction,
  asset,
  value,
  CASE
    WHEN usd_raw IS NULL AND asset IN (SELECT asset FROM v_stablecoins) THEN value
    ELSE usd_raw
  END AS usd
FROM typed;

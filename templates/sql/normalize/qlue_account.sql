CREATE OR REPLACE TEMP VIEW norm_{{FILE_ID}} AS
WITH base AS (
  SELECT DISTINCT
    'qlue' AS vendor,
    'account' AS tx_model,
    '{{SOURCE_FILE}}' AS source_file,
    '{{BLOCKCHAIN}}' AS blockchain,
    nullif(trim(cast("Time" AS VARCHAR)), '') AS time_raw,
    nullif(trim(cast("Transaction" AS VARCHAR)), '') AS tx,
    nullif(trim(regexp_replace(replace(coalesce(cast("Transfer Label" AS VARCHAR), ''), '"', ''), '\s+', ' ', 'g')), '') AS tx_label,
    nullif(trim(cast("Source Address Hash" AS VARCHAR)), '') AS source_address,
    nullif(trim(regexp_replace(replace(coalesce(cast("Source Address Label" AS VARCHAR), ''), '"', ''), '\s+', ' ', 'g')), '') AS source_label,
    nullif(trim(cast("Source Group" AS VARCHAR)), '') AS source_group,
    nullif(trim(cast("Source Group Description" AS VARCHAR)), '') AS source_group_description,
    nullif(trim(cast("Recipient Address Hash" AS VARCHAR)), '') AS destination_address,
    nullif(trim(regexp_replace(replace(coalesce(cast("Recipient Address Label" AS VARCHAR), ''), '"', ''), '\s+', ' ', 'g')), '') AS destination_label,
    nullif(trim(cast("Recipient Group" AS VARCHAR)), '') AS destination_group,
    nullif(trim(cast("Recipient Group Description" AS VARCHAR)), '') AS destination_group_description,
    upper(nullif(trim(cast("Crypto Asset" AS VARCHAR)), '')) AS asset,
    try_cast(replace(nullif(trim(cast("Crypto Value" AS VARCHAR)), ''), ',', '') AS DOUBLE) AS value,
    try_cast(replace(replace(nullif(trim(cast("USD" AS VARCHAR)), ''), ',', ''), '$', '') AS DOUBLE) AS usd_raw
  FROM {{RAW_TABLE}}
  WHERE nullif(trim(cast("Transaction" AS VARCHAR)), '') IS NOT NULL
), typed AS (
  SELECT
    *,
    coalesce(
      try_strptime(
        regexp_replace(replace(time_raw, ' GMT+0', ''), '^(\w+)\s+(\d)\s', '\1 0\2 '),
        '%B %d %Y %I:%M:%S %p'
      ),
      try_strptime(
        regexp_replace(replace(time_raw, ' GMT+0', ''), '^(\w+)\s+(\d)\s', '\1 0\2 '),
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
  asset,
  value,
  CASE
    WHEN usd_raw IS NULL AND asset IN (SELECT asset FROM v_stablecoins) THEN value
    ELSE usd_raw
  END AS usd
FROM typed;

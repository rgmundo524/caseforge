CREATE OR REPLACE TEMP VIEW trm_address_lookup_{{FILE_ID}} AS
SELECT
    lower(trim(cast("Address" AS VARCHAR))) AS address_key,
    max(nullif(trim(cast("Name" AS VARCHAR)), '')) AS label,
    max(nullif(trim(cast("Entity URN" AS VARCHAR)), '')) AS grp,
    max(nullif(trim(cast("Categories" AS VARCHAR)), '')) AS grp_desc,
    max(try_cast(nullif(trim(cast("Risk Score" AS VARCHAR)), '') AS DOUBLE)) AS risk_score
FROM {{RAW_TABLE}}
WHERE lower(trim(cast("Type" AS VARCHAR))) = 'address'
  AND nullif(trim(cast("Address" AS VARCHAR)), '') IS NOT NULL
GROUP BY 1;

CREATE OR REPLACE TEMP VIEW norm_{{FILE_ID}} AS
WITH tx_base AS (
    SELECT DISTINCT
        'trm' AS vendor,
        'account' AS tx_model,
        '{{SOURCE_FILE}}' AS source_file,
        nullif(trim(cast("Chain" AS VARCHAR)), '') AS blockchain,
        try_cast(nullif(trim(cast("Timestamp" AS VARCHAR)), '') AS TIMESTAMP) AS time,
        nullif(trim(cast("Txn Hash" AS VARCHAR)), '') AS tx,
        nullif(trim(cast("Notes" AS VARCHAR)), '') AS tx_label,
        nullif(trim(cast("From" AS VARCHAR)), '') AS source_address,
        lower(trim(cast("From" AS VARCHAR))) AS source_address_key,
        nullif(trim(cast("To" AS VARCHAR)), '') AS destination_address,
        lower(trim(cast("To" AS VARCHAR))) AS destination_address_key,
        nullif(trim(cast("Asset" AS VARCHAR)), '') AS asset,
        try_cast(replace(nullif(trim(cast("Value" AS VARCHAR)), ''), ',', '') AS DOUBLE) AS value,
        try_cast(replace(replace(nullif(trim(cast("Value USD" AS VARCHAR)), ''), ',', ''), '$', '') AS DOUBLE) AS usd
    FROM {{RAW_TABLE}}
    WHERE lower(trim(cast("Type" AS VARCHAR))) = 'transfer'
      AND nullif(trim(cast("Txn Hash" AS VARCHAR)), '') IS NOT NULL
)
SELECT
    t.vendor,
    t.tx_model,
    t.source_file,
    t.blockchain,
    t.time,
    t.tx,
    t.tx_label,
    t.source_address,
    sf.label AS source_label,
    sf.grp AS source_group,
    sf.grp_desc AS source_group_description,
    t.destination_address,
    df.label AS destination_label,
    df.grp AS destination_group,
    df.grp_desc AS destination_group_description,
    t.asset,
    t.value,
    t.usd
FROM tx_base t
LEFT JOIN trm_address_lookup_{{FILE_ID}} sf
    ON sf.address_key = t.source_address_key
LEFT JOIN trm_address_lookup_{{FILE_ID}} df
    ON df.address_key = t.destination_address_key;

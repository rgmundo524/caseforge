CREATE OR REPLACE TEMP VIEW norm_{{FILE_ID}} AS
SELECT DISTINCT
    'qlue' AS vendor,
    'account' AS tx_model,
    '{{SOURCE_FILE}}' AS source_file,
    '{{BLOCKCHAIN}}' AS blockchain,
    coalesce(
        try_strptime(
            replace(nullif(trim(cast("Time" AS VARCHAR)), ''), ' GMT+0', ' +00'),
            '%B %-d %Y %-I:%M:%S %p %z'
        ),
        try_strptime(
            replace(nullif(trim(cast("Time" AS VARCHAR)), ''), ' GMT+0', ' +00'),
            '%B %d %Y %-I:%M:%S %p %z'
        )
    ) AS time,
    nullif(trim(cast("Transaction" AS VARCHAR)), '') AS tx,
    nullif(trim(cast("Transfer Label" AS VARCHAR)), '') AS tx_label,
    nullif(trim(cast("Source Address Hash" AS VARCHAR)), '') AS source_address,
    nullif(trim(cast("Source Address Label" AS VARCHAR)), '') AS source_label,
    nullif(trim(cast("Source Group" AS VARCHAR)), '') AS source_group,
    nullif(trim(cast("Source Group Description" AS VARCHAR)), '') AS source_group_description,
    nullif(trim(cast("Recipient Address Hash" AS VARCHAR)), '') AS destination_address,
    nullif(trim(cast("Recipient Address Label" AS VARCHAR)), '') AS destination_label,
    nullif(trim(cast("Recipient Group" AS VARCHAR)), '') AS destination_group,
    nullif(trim(cast("Recipient Group Description" AS VARCHAR)), '') AS destination_group_description,
    nullif(trim(cast("Crypto Asset" AS VARCHAR)), '') AS asset,
    try_cast(replace(nullif(trim(cast("Crypto Value" AS VARCHAR)), ''), ',', '') AS DOUBLE) AS value,
    try_cast(replace(replace(nullif(trim(cast("USD" AS VARCHAR)), ''), ',', ''), '$', '') AS DOUBLE) AS usd
FROM {{RAW_TABLE}}
WHERE nullif(trim(cast("Transaction" AS VARCHAR)), '') IS NOT NULL;

CREATE OR REPLACE TEMP VIEW norm_{{FILE_ID}} AS
WITH base AS (
    SELECT
        nullif(trim(cast("Transaction Hash" AS VARCHAR)), '') AS tx,
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
        nullif(trim(cast("Transaction Label" AS VARCHAR)), '') AS tx_label,
        CASE
            WHEN lower(trim(cast("Direction" AS VARCHAR))) IN ('in', 'input', 'incoming') THEN 'in'
            WHEN lower(trim(cast("Direction" AS VARCHAR))) IN ('out', 'output', 'outgoing') THEN 'out'
            ELSE null
        END AS direction_norm,
        nullif(trim(cast("Address Hash" AS VARCHAR)), '') AS address_hash,
        nullif(trim(cast("Address Label" AS VARCHAR)), '') AS address_label,
        nullif(trim(cast("Source Group" AS VARCHAR)), '') AS source_group,
        nullif(trim(cast("Source Group Description" AS VARCHAR)), '') AS source_group_description,
        nullif(trim(cast("Recipient Group" AS VARCHAR)), '') AS recipient_group,
        nullif(trim(cast("Recipient Group Description" AS VARCHAR)), '') AS recipient_group_description,
        nullif(trim(cast("Token Policy" AS VARCHAR)), '') AS token_policy,
        nullif(trim(cast("Crypto Value" AS VARCHAR)), '') AS crypto_value_raw,
        try_cast(
            replace(regexp_extract(nullif(trim(cast("Crypto Value" AS VARCHAR)), ''), '[-+]?[0-9][0-9,]*(\\.[0-9]+)?'), ',', '')
            AS DOUBLE
        ) AS row_value,
        nullif(
            trim(regexp_replace(nullif(trim(cast("Crypto Value" AS VARCHAR)), ''), '[-+]?[0-9][0-9,]*(\\.[0-9]+)?', '')),
            ''
        ) AS row_asset,
        try_cast(replace(replace(nullif(trim(cast("USD" AS VARCHAR)), ''), ',', ''), '$', '') AS DOUBLE) AS usd
    FROM {{RAW_TABLE}}
    WHERE nullif(trim(cast("Transaction Hash" AS VARCHAR)), '') IS NOT NULL
)
SELECT
    'qlue' AS vendor,
    'utxo' AS tx_model,
    '{{SOURCE_FILE}}' AS source_file,
    '{{BLOCKCHAIN}}' AS blockchain,
    min(time) AS time,
    tx,
    max(tx_label) AS tx_label,
    (
        SELECT string_agg(address_hash, ' | ')
        FROM (
            SELECT DISTINCT address_hash
            FROM base bi
            WHERE bi.tx = b.tx
              AND bi.direction_norm = 'in'
              AND bi.address_hash IS NOT NULL
            ORDER BY 1
        )
    ) AS source_address,
    (
        SELECT string_agg(address_label, ' | ')
        FROM (
            SELECT DISTINCT address_label
            FROM base bi
            WHERE bi.tx = b.tx
              AND bi.direction_norm = 'in'
              AND bi.address_label IS NOT NULL
            ORDER BY 1
        )
    ) AS source_label,
    (
        SELECT string_agg(source_group, ' | ')
        FROM (
            SELECT DISTINCT source_group
            FROM base bi
            WHERE bi.tx = b.tx
              AND bi.direction_norm = 'in'
              AND bi.source_group IS NOT NULL
            ORDER BY 1
        )
    ) AS source_group,
    (
        SELECT string_agg(source_group_description, ' | ')
        FROM (
            SELECT DISTINCT source_group_description
            FROM base bi
            WHERE bi.tx = b.tx
              AND bi.direction_norm = 'in'
              AND bi.source_group_description IS NOT NULL
            ORDER BY 1
        )
    ) AS source_group_description,
    (
        SELECT string_agg(address_hash, ' | ')
        FROM (
            SELECT DISTINCT address_hash
            FROM base bo
            WHERE bo.tx = b.tx
              AND bo.direction_norm = 'out'
              AND bo.address_hash IS NOT NULL
            ORDER BY 1
        )
    ) AS destination_address,
    (
        SELECT string_agg(address_label, ' | ')
        FROM (
            SELECT DISTINCT address_label
            FROM base bo
            WHERE bo.tx = b.tx
              AND bo.direction_norm = 'out'
              AND bo.address_label IS NOT NULL
            ORDER BY 1
        )
    ) AS destination_label,
    (
        SELECT string_agg(recipient_group, ' | ')
        FROM (
            SELECT DISTINCT recipient_group
            FROM base bo
            WHERE bo.tx = b.tx
              AND bo.direction_norm = 'out'
              AND bo.recipient_group IS NOT NULL
            ORDER BY 1
        )
    ) AS destination_group,
    (
        SELECT string_agg(recipient_group_description, ' | ')
        FROM (
            SELECT DISTINCT recipient_group_description
            FROM base bo
            WHERE bo.tx = b.tx
              AND bo.direction_norm = 'out'
              AND bo.recipient_group_description IS NOT NULL
            ORDER BY 1
        )
    ) AS destination_group_description,
    coalesce(max(token_policy), max(row_asset)) AS asset,
    sum(CASE WHEN direction_norm = 'out' THEN coalesce(row_value, 0) ELSE 0 END) AS value,
    sum(CASE WHEN direction_norm = 'out' THEN coalesce(usd, 0) ELSE 0 END) AS usd
FROM base b
GROUP BY tx;

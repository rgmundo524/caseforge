CREATE OR REPLACE TEMP VIEW trm_address_lookup_{{FILE_ID}} AS
SELECT
    lower(trim(cast("Address" AS VARCHAR))) AS address_key,
    max(nullif(trim(cast("Name" AS VARCHAR)), '')) AS label,
    max(nullif(trim(cast("Entity URN" AS VARCHAR)), '')) AS grp,
    max(nullif(trim(cast("Categories" AS VARCHAR)), '')) AS grp_desc
FROM {{RAW_TABLE}}
WHERE lower(trim(cast("Type" AS VARCHAR))) = 'address'
  AND nullif(trim(cast("Address" AS VARCHAR)), '') IS NOT NULL
GROUP BY 1;

CREATE OR REPLACE TEMP VIEW norm_{{FILE_ID}} AS
WITH tx_base AS (
    SELECT
        nullif(trim(cast("Txn Hash" AS VARCHAR)), '') AS tx,
        max(nullif(trim(cast("Chain" AS VARCHAR)), '')) AS blockchain,
        try_cast(max(nullif(trim(cast("Timestamp" AS VARCHAR)), '')) AS TIMESTAMP) AS time,
        max(nullif(trim(cast("Notes" AS VARCHAR)), '')) AS tx_label,
        max(nullif(trim(cast("Asset" AS VARCHAR)), '')) AS asset,
        max(try_cast(replace(nullif(trim(cast("Value" AS VARCHAR)), ''), ',', '') AS DOUBLE)) AS value,
        max(try_cast(replace(replace(nullif(trim(cast("Value USD" AS VARCHAR)), ''), ',', ''), '$', '') AS DOUBLE)) AS usd
    FROM {{RAW_TABLE}}
    WHERE lower(trim(cast("Type" AS VARCHAR))) = 'transfer'
      AND nullif(trim(cast("Txn Hash" AS VARCHAR)), '') IS NOT NULL
    GROUP BY 1
),
distinct_in AS (
    SELECT DISTINCT
        nullif(trim(cast("Txn Hash" AS VARCHAR)), '') AS tx,
        lower(trim(cast("From" AS VARCHAR))) AS address_key,
        nullif(trim(cast("From" AS VARCHAR)), '') AS address
    FROM {{RAW_TABLE}}
    WHERE lower(trim(cast("Type" AS VARCHAR))) = 'transfer'
      AND nullif(trim(cast("Txn Hash" AS VARCHAR)), '') IS NOT NULL
      AND nullif(trim(cast("From" AS VARCHAR)), '') IS NOT NULL
),
distinct_out AS (
    SELECT DISTINCT
        nullif(trim(cast("Txn Hash" AS VARCHAR)), '') AS tx,
        lower(trim(cast("To" AS VARCHAR))) AS address_key,
        nullif(trim(cast("To" AS VARCHAR)), '') AS address
    FROM {{RAW_TABLE}}
    WHERE lower(trim(cast("Type" AS VARCHAR))) = 'transfer'
      AND nullif(trim(cast("Txn Hash" AS VARCHAR)), '') IS NOT NULL
      AND nullif(trim(cast("To" AS VARCHAR)), '') IS NOT NULL
)
SELECT
    'trm' AS vendor,
    'utxo' AS tx_model,
    '{{SOURCE_FILE}}' AS source_file,
    b.blockchain,
    b.time,
    b.tx,
    b.tx_label,
    (
        SELECT string_agg(address, ' | ')
        FROM (
            SELECT DISTINCT address
            FROM distinct_in di
            WHERE di.tx = b.tx
            ORDER BY 1
        )
    ) AS source_address,
    (
        SELECT string_agg(label, ' | ')
        FROM (
            SELECT DISTINCT l.label
            FROM distinct_in di
            LEFT JOIN trm_address_lookup_{{FILE_ID}} l
              ON l.address_key = di.address_key
            WHERE di.tx = b.tx
              AND l.label IS NOT NULL
            ORDER BY 1
        )
    ) AS source_label,
    (
        SELECT string_agg(grp, ' | ')
        FROM (
            SELECT DISTINCT l.grp
            FROM distinct_in di
            LEFT JOIN trm_address_lookup_{{FILE_ID}} l
              ON l.address_key = di.address_key
            WHERE di.tx = b.tx
              AND l.grp IS NOT NULL
            ORDER BY 1
        )
    ) AS source_group,
    (
        SELECT string_agg(grp_desc, ' | ')
        FROM (
            SELECT DISTINCT l.grp_desc
            FROM distinct_in di
            LEFT JOIN trm_address_lookup_{{FILE_ID}} l
              ON l.address_key = di.address_key
            WHERE di.tx = b.tx
              AND l.grp_desc IS NOT NULL
            ORDER BY 1
        )
    ) AS source_group_description,
    (
        SELECT string_agg(address, ' | ')
        FROM (
            SELECT DISTINCT address
            FROM distinct_out do_
            WHERE do_.tx = b.tx
            ORDER BY 1
        )
    ) AS destination_address,
    (
        SELECT string_agg(label, ' | ')
        FROM (
            SELECT DISTINCT l.label
            FROM distinct_out do_
            LEFT JOIN trm_address_lookup_{{FILE_ID}} l
              ON l.address_key = do_.address_key
            WHERE do_.tx = b.tx
              AND l.label IS NOT NULL
            ORDER BY 1
        )
    ) AS destination_label,
    (
        SELECT string_agg(grp, ' | ')
        FROM (
            SELECT DISTINCT l.grp
            FROM distinct_out do_
            LEFT JOIN trm_address_lookup_{{FILE_ID}} l
              ON l.address_key = do_.address_key
            WHERE do_.tx = b.tx
              AND l.grp IS NOT NULL
            ORDER BY 1
        )
    ) AS destination_group,
    (
        SELECT string_agg(grp_desc, ' | ')
        FROM (
            SELECT DISTINCT l.grp_desc
            FROM distinct_out do_
            LEFT JOIN trm_address_lookup_{{FILE_ID}} l
              ON l.address_key = do_.address_key
            WHERE do_.tx = b.tx
              AND l.grp_desc IS NOT NULL
            ORDER BY 1
        )
    ) AS destination_group_description,
    b.asset,
    b.value,
    b.usd
FROM tx_base b;

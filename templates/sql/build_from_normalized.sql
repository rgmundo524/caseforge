PRAGMA threads=4;

-- v_stablecoins is created during normalize bootstrap and persisted in case.duckdb.
-- It is intentionally injected from repo config by Python so DuckDB does not
-- depend on a case-root-relative file path here.

CREATE OR REPLACE VIEW v_transfers AS
WITH base AS (
  SELECT
    vendor,
    CASE
      WHEN vendor = 'trm'  AND tx_model = 'account' THEN 'trm'
      WHEN vendor = 'trm'  AND tx_model = 'utxo'    THEN 'trm'
      WHEN vendor = 'qlue' AND tx_model = 'account' THEN 'qlue_account'
      WHEN vendor = 'qlue' AND tx_model = 'utxo'    THEN 'qlue_utxo'
      ELSE vendor || '_' || tx_model
    END AS format,
    blockchain AS chain,
    time AS ts,
    tx AS tx_hash,
    source_address AS from_address,
    destination_address AS to_address,
    nullif(trim(regexp_replace(replace(replace(replace(coalesce(source_label, ''), '"', ''), '{', '['), '}', ']'), '\s+', ' ', 'g')), '') AS from_label,
    nullif(trim(regexp_replace(replace(replace(replace(coalesce(destination_label, ''), '"', ''), '{', '['), '}', ']'), '\s+', ' ', 'g')), '') AS to_label,
    NULL::VARCHAR AS address_label,
    CASE WHEN tx_model = 'utxo' THEN 'utxo' ELSE NULL END AS direction,
    upper(nullif(trim(asset), '')) AS asset,
    value AS amount_value,
    CASE
      WHEN usd IS NULL AND upper(nullif(trim(asset), '')) IN (SELECT asset FROM v_stablecoins) THEN value
      ELSE usd
    END AS amount_usd_value,
    nullif(trim(regexp_replace(replace(replace(replace(coalesce(tx_label, ''), '"', ''), '{', '['), '}', ']'), '\s+', ' ', 'g')), '') AS transfer_label,
    source_file
  FROM normalized_combined_transactions
), labels AS (
  SELECT
    *,
    trim(coalesce(transfer_label, '')) AS transfer_label_clean,
    trim(coalesce(from_label, ''))     AS from_label_clean,
    trim(coalesce(to_label, ''))       AS to_label_clean
  FROM base
), parsed AS (
  SELECT
    *,
    nullif(trim(regexp_extract(transfer_label_clean, '^\[([^]]+)\]', 1)), '') AS tx_label_actions,
    nullif(trim(regexp_extract(from_label_clean,     '^\[([^]]+)\]', 1)), '') AS from_types,
    nullif(trim(regexp_extract(to_label_clean,       '^\[([^]]+)\]', 1)), '') AS to_types,

    nullif(
      trim(
        regexp_replace(
          trim(regexp_replace(transfer_label_clean, '^\[[^]]+\]\s*', '')),
          '\s*\([^)]*\)\s*$',
          ''
        )
      ),
      ''
    ) AS tx_label_counterparty_raw,
    nullif(
      trim(
        regexp_replace(
          trim(regexp_replace(from_label_clean, '^\[[^]]+\]\s*', '')),
          '\s*\([^)]*\)\s*$',
          ''
        )
      ),
      ''
    ) AS from_counterparty_raw,
    nullif(
      trim(
        regexp_replace(
          trim(regexp_replace(to_label_clean, '^\[[^]]+\]\s*', '')),
          '\s*\([^)]*\)\s*$',
          ''
        )
      ),
      ''
    ) AS to_counterparty_raw,

    nullif(trim(regexp_extract(transfer_label_clean, '\(([^)]*)\)\s*$', 1)), '') AS tx_paren_body,
    nullif(trim(regexp_extract(from_label_clean,     '\(([^)]*)\)\s*$', 1)), '') AS from_paren_body,
    nullif(trim(regexp_extract(to_label_clean,       '\(([^)]*)\)\s*$', 1)), '') AS to_paren_body
  FROM labels
), measured AS (
  SELECT
    *,
    try_cast(
      replace(
        regexp_extract(coalesce(tx_paren_body, ''), '([-+]?(?:[0-9][0-9,]*(?:\.[0-9]+)?|\.[0-9]+))', 1),
        ',',
        ''
      ) AS DOUBLE
    ) AS tx_label_value_raw,
    upper(nullif(trim(regexp_extract(coalesce(tx_paren_body, ''), '^[^A-Za-z0-9._-]*[-+]?(?:[0-9][0-9,]*(?:\.[0-9]+)?|\.[0-9]+)\s*([A-Za-z0-9._-]+)\s*$', 1)), '')) AS tx_label_asset_raw,
    regexp_matches(coalesce(tx_paren_body, ''), '[A-Za-z]')
      AND NOT regexp_matches(coalesce(tx_paren_body, ''), '[-+]?(?:[0-9][0-9,]*(?:\.[0-9]+)?|\.[0-9]+)') AS tx_asset_without_value,

    try_cast(
      replace(
        regexp_extract(coalesce(from_paren_body, ''), '([-+]?(?:[0-9][0-9,]*(?:\.[0-9]+)?|\.[0-9]+))', 1),
        ',',
        ''
      ) AS DOUBLE
    ) AS from_dormant_value_raw,
    upper(nullif(trim(regexp_extract(coalesce(from_paren_body, ''), '^[^A-Za-z0-9._-]*[-+]?(?:[0-9][0-9,]*(?:\.[0-9]+)?|\.[0-9]+)\s*([A-Za-z0-9._-]+)\s*$', 1)), '')) AS from_dormant_asset_raw,
    regexp_matches(coalesce(from_paren_body, ''), '[A-Za-z]')
      AND NOT regexp_matches(coalesce(from_paren_body, ''), '[-+]?(?:[0-9][0-9,]*(?:\.[0-9]+)?|\.[0-9]+)') AS from_asset_without_value,

    try_cast(
      replace(
        regexp_extract(coalesce(to_paren_body, ''), '([-+]?(?:[0-9][0-9,]*(?:\.[0-9]+)?|\.[0-9]+))', 1),
        ',',
        ''
      ) AS DOUBLE
    ) AS to_dormant_value_raw,
    upper(nullif(trim(regexp_extract(coalesce(to_paren_body, ''), '^[^A-Za-z0-9._-]*[-+]?(?:[0-9][0-9,]*(?:\.[0-9]+)?|\.[0-9]+)\s*([A-Za-z0-9._-]+)\s*$', 1)), '')) AS to_dormant_asset_raw,
    regexp_matches(coalesce(to_paren_body, ''), '[A-Za-z]')
      AND NOT regexp_matches(coalesce(to_paren_body, ''), '[-+]?(?:[0-9][0-9,]*(?:\.[0-9]+)?|\.[0-9]+)') AS to_asset_without_value
  FROM parsed
), normalized AS (
  SELECT
    *,
    CASE
      WHEN tx_label_counterparty_raw IS NOT NULL AND regexp_matches(tx_label_counterparty_raw, '[A-Za-z]') THEN tx_label_counterparty_raw
      ELSE NULL
    END AS tx_label_counterparty,
    CASE
      WHEN from_counterparty_raw IS NOT NULL AND regexp_matches(from_counterparty_raw, '[A-Za-z]') THEN from_counterparty_raw
      ELSE NULL
    END AS from_counterparty,
    CASE
      WHEN to_counterparty_raw IS NOT NULL AND regexp_matches(to_counterparty_raw, '[A-Za-z]') THEN to_counterparty_raw
      ELSE NULL
    END AS to_counterparty,

    CASE
      WHEN tx_label_value_raw IS NULL THEN NULL
      ELSE tx_label_value_raw
    END AS tx_label_value,
    CASE
      WHEN tx_label_value_raw IS NULL THEN NULL
      ELSE coalesce(tx_label_asset_raw, asset)
    END AS tx_label_asset,
    CASE
      WHEN from_dormant_value_raw IS NULL THEN NULL
      ELSE from_dormant_value_raw
    END AS from_dormant_value,
    CASE
      WHEN from_dormant_value_raw IS NULL THEN NULL
      ELSE coalesce(from_dormant_asset_raw, asset)
    END AS from_dormant_asset,
    CASE
      WHEN to_dormant_value_raw IS NULL THEN NULL
      ELSE to_dormant_value_raw
    END AS to_dormant_value,
    CASE
      WHEN to_dormant_value_raw IS NULL THEN NULL
      ELSE coalesce(to_dormant_asset_raw, asset)
    END AS to_dormant_asset,

    CASE
      WHEN transfer_label IS NULL THEN 'unlabeled'
      WHEN tx_asset_without_value THEN 'malformed'
      WHEN tx_label_actions IS NOT NULL OR tx_label_counterparty_raw IS NOT NULL OR tx_label_value_raw IS NOT NULL THEN 'parsed'
      ELSE 'malformed'
    END AS tx_label_status,
    CASE
      WHEN from_label IS NULL THEN 'unlabeled'
      WHEN from_asset_without_value THEN 'malformed'
      WHEN from_types IS NOT NULL OR from_counterparty_raw IS NOT NULL OR from_dormant_value_raw IS NOT NULL THEN 'parsed'
      ELSE 'malformed'
    END AS from_label_status,
    CASE
      WHEN to_label IS NULL THEN 'unlabeled'
      WHEN to_asset_without_value THEN 'malformed'
      WHEN to_types IS NOT NULL OR to_counterparty_raw IS NOT NULL OR to_dormant_value_raw IS NOT NULL THEN 'parsed'
      ELSE 'malformed'
    END AS to_label_status,

    CASE
      WHEN ts IS NULL THEN 'missing_or_unparsed'
      ELSE 'parsed'
    END AS time_status,
    CASE
      WHEN amount_value IS NULL THEN 'missing'
      WHEN asset IS NULL THEN 'missing_asset'
      ELSE 'parsed'
    END AS amount_status,
    CASE
      WHEN amount_usd_value IS NULL AND asset IN (SELECT asset FROM v_stablecoins) THEN 'inferred_from_stablecoin'
      WHEN amount_usd_value IS NULL THEN 'missing'
      ELSE 'parsed'
    END AS usd_status,

    regexp_matches(coalesce(tx_label_actions, ''), '(^|[/\\])THEFT($|[/\\])', 'i') AS tx_is_theft,
    regexp_matches(coalesce(tx_label_actions, ''), '(^|[/\\])CC:[0-9]+:(IN|OUT)($|[/\\])', 'i') AS tx_is_cross_chain,
    try_cast(regexp_extract(coalesce(tx_label_actions, ''), '(^|[/\\])CC:([0-9]+):(IN|OUT)($|[/\\])', 2) AS INTEGER) AS tx_cc_id,
    upper(nullif(regexp_extract(coalesce(tx_label_actions, ''), '(^|[/\\])CC:([0-9]+):(IN|OUT)($|[/\\])', 3), '')) AS tx_cc_direction
  FROM measured
), theft_transactions AS (
  SELECT
    tx_hash,
    row_number() OVER (ORDER BY min(ts) NULLS LAST, tx_hash) AS theft_id
  FROM normalized
  WHERE tx_is_theft
    AND tx_hash IS NOT NULL
  GROUP BY tx_hash
), final AS (
  SELECT
    n.vendor,
    n.format,
    n.chain,
    n.ts,
    n.tx_hash,
    n.from_address,
    n.to_address,
    n.from_label,
    n.to_label,
    n.address_label,
    n.direction,
    n.asset,
    n.amount_value,
    n.amount_usd_value,
    n.transfer_label,
    t.theft_id,
    CASE
      WHEN n.amount_value IS NULL THEN n.tx_label_value
      WHEN n.tx_label_value IS NULL THEN n.amount_value
      ELSE LEAST(n.amount_value, n.tx_label_value)
    END AS stolen_amount_value,
    n.source_file,
    n.tx_label_actions,
    n.tx_label_counterparty,
    n.tx_label_value,
    n.tx_label_asset,
    n.tx_label_status,
    n.from_types,
    n.from_counterparty,
    n.from_dormant_value,
    n.from_dormant_asset,
    n.from_label_status,
    n.to_types,
    n.to_counterparty,
    n.to_dormant_value,
    n.to_dormant_asset,
    n.to_label_status,
    n.tx_is_theft,
    n.tx_is_cross_chain,
    n.tx_cc_id,
    n.tx_cc_direction,
    n.time_status,
    n.amount_status,
    n.usd_status
  FROM normalized n
  LEFT JOIN theft_transactions t USING (tx_hash)
)
SELECT
  *,
  CASE
    WHEN amount_value IS NULL OR amount_usd_value IS NULL OR amount_value = 0 THEN NULL
    ELSE LEAST(amount_usd_value, amount_usd_value * (stolen_amount_value / amount_value))
  END AS stolen_amount_usd_value
FROM final;

CREATE OR REPLACE VIEW transactions AS
SELECT * FROM v_transfers;

CREATE OR REPLACE VIEW v_normalized_transactions AS
SELECT * FROM normalized_combined_transactions;

CREATE OR REPLACE VIEW v_cross_chain_pairs AS
WITH cc AS (
  SELECT *
  FROM transactions
  WHERE tx_is_cross_chain
    AND tx_cc_id IS NOT NULL
), cc_in AS (
  SELECT * FROM cc WHERE tx_cc_direction = 'IN'
), cc_out AS (
  SELECT * FROM cc WHERE tx_cc_direction = 'OUT'
)
SELECT
  coalesce(i.tx_cc_id, o.tx_cc_id) AS tx_cc_id,
  i.tx_hash        AS in_tx_hash,
  i.chain          AS in_chain,
  i.asset          AS in_asset,
  i.amount_value   AS in_amount_value,
  i.tx_label_value AS in_label_value,
  i.tx_label_asset AS in_label_asset,
  i.ts             AS in_ts,
  o.tx_hash        AS out_tx_hash,
  o.chain          AS out_chain,
  o.asset          AS out_asset,
  o.amount_value   AS out_amount_value,
  o.tx_label_value AS out_label_value,
  o.tx_label_asset AS out_label_asset,
  o.ts             AS out_ts,
  CASE
    WHEN i.tx_hash IS NULL THEN 'missing_in'
    WHEN o.tx_hash IS NULL THEN 'missing_out'
    ELSE 'paired'
  END AS cc_pair_status
FROM cc_in i
FULL OUTER JOIN cc_out o
  ON i.tx_cc_id = o.tx_cc_id;

CREATE OR REPLACE VIEW v_issue_rows AS
SELECT
  *,
  trim(
    both '|' FROM concat(
      CASE WHEN tx_label_status   = 'malformed'         THEN 'tx_label_malformed|'            ELSE '' END,
      CASE WHEN from_label_status = 'malformed'         THEN 'from_label_malformed|'          ELSE '' END,
      CASE WHEN to_label_status   = 'malformed'         THEN 'to_label_malformed|'            ELSE '' END,
      CASE WHEN time_status      <> 'parsed'            THEN 'time_issue|'                    ELSE '' END,
      CASE WHEN amount_status    <> 'parsed'            THEN 'amount_issue|'                  ELSE '' END,
      CASE WHEN tx_label_value IS NOT NULL AND amount_value IS NOT NULL AND tx_label_value > amount_value
                                                     THEN 'label_value_exceeds_amount|'       ELSE '' END
    )
  ) AS issue_flags
FROM transactions
WHERE tx_label_status = 'malformed'
   OR from_label_status = 'malformed'
   OR to_label_status = 'malformed'
   OR time_status <> 'parsed'
   OR amount_status <> 'parsed'
   OR (tx_label_value IS NOT NULL AND amount_value IS NOT NULL AND tx_label_value > amount_value);

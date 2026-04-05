PRAGMA threads=4;

-- Assumes normalize.py has already created v_stablecoins.
-- This build keeps one row per normalized transfer leg.

CREATE OR REPLACE VIEW v_transfers AS
WITH base AS (
  SELECT
    vendor,
    tx_model,
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
    lower(nullif(trim(direction), '')) AS direction,
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
    trim(coalesce(from_label, '')) AS from_label_clean,
    trim(coalesce(to_label, '')) AS to_label_clean
  FROM base
), parsed AS (
  SELECT
    *,
    nullif(trim(regexp_extract(transfer_label_clean, '^\[([^]]+)\]', 1)), '') AS tx_label_actions,
    nullif(trim(regexp_extract(from_label_clean, '^\[([^]]+)\]', 1)), '') AS from_types,
    nullif(trim(regexp_extract(to_label_clean, '^\[([^]]+)\]', 1)), '') AS to_types,

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
    nullif(trim(regexp_extract(from_label_clean, '\(([^)]*)\)\s*$', 1)), '') AS from_paren_body,
    nullif(trim(regexp_extract(to_label_clean, '\(([^)]*)\)\s*$', 1)), '') AS to_paren_body,

    CASE
      WHEN regexp_matches(transfer_label_clean, '^\s*[-+]?(?:[0-9][0-9,]*(?:\.[0-9]+)?|\.[0-9]+)\s*$')
        THEN nullif(trim(transfer_label_clean), '')
      ELSE NULL
    END AS tx_plain_numeric_token
  FROM labels
), measured AS (
  SELECT
    *,
    nullif(trim(regexp_extract(coalesce(tx_paren_body, ''), '^\s*([-+]?(?:[0-9][0-9,]*(?:\.[0-9]+)?|\.[0-9]+))', 1)), '') AS tx_value_token,
    nullif(trim(regexp_replace(coalesce(tx_paren_body, ''), '^\s*[-+]?(?:[0-9][0-9,]*(?:\.[0-9]+)?|\.[0-9]+)\s*', '')), '') AS tx_tail_raw,

    nullif(trim(regexp_extract(coalesce(from_paren_body, ''), '^\s*([-+]?(?:[0-9][0-9,]*(?:\.[0-9]+)?|\.[0-9]+))', 1)), '') AS from_value_token,
    nullif(trim(regexp_replace(coalesce(from_paren_body, ''), '^\s*[-+]?(?:[0-9][0-9,]*(?:\.[0-9]+)?|\.[0-9]+)\s*', '')), '') AS from_tail_raw,

    nullif(trim(regexp_extract(coalesce(to_paren_body, ''), '^\s*([-+]?(?:[0-9][0-9,]*(?:\.[0-9]+)?|\.[0-9]+))', 1)), '') AS to_value_token,
    nullif(trim(regexp_replace(coalesce(to_paren_body, ''), '^\s*[-+]?(?:[0-9][0-9,]*(?:\.[0-9]+)?|\.[0-9]+)\s*', '')), '') AS to_tail_raw,

    try_cast(replace(tx_plain_numeric_token, ',', '') AS DOUBLE) AS tx_plain_numeric_value
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

    coalesce(
      try_cast(replace(tx_value_token, ',', '') AS DOUBLE),
      tx_plain_numeric_value
    ) AS tx_label_value,
    CASE
      WHEN tx_value_token IS NOT NULL THEN
        CASE
          WHEN tx_tail_raw IS NULL THEN asset
          ELSE upper(tx_tail_raw)
        END
      WHEN tx_plain_numeric_value IS NOT NULL THEN asset
      ELSE NULL
    END AS tx_label_asset,

    try_cast(replace(from_value_token, ',', '') AS DOUBLE) AS from_dormant_value,
    CASE
      WHEN from_value_token IS NULL THEN NULL
      WHEN from_tail_raw IS NULL THEN asset
      ELSE upper(from_tail_raw)
    END AS from_dormant_asset,

    try_cast(replace(to_value_token, ',', '') AS DOUBLE) AS to_dormant_value,
    CASE
      WHEN to_value_token IS NULL THEN NULL
      WHEN to_tail_raw IS NULL THEN asset
      ELSE upper(to_tail_raw)
    END AS to_dormant_asset,

    CASE
      WHEN transfer_label IS NULL THEN 'unlabeled'
      WHEN tx_paren_body IS NOT NULL AND tx_value_token IS NULL THEN 'malformed'
      WHEN tx_plain_numeric_value IS NOT NULL THEN 'parsed_inferred_asset'
      WHEN tx_label_actions IS NOT NULL
        OR (tx_label_counterparty_raw IS NOT NULL AND regexp_matches(tx_label_counterparty_raw, '[A-Za-z]'))
        OR coalesce(try_cast(replace(tx_value_token, ',', '') AS DOUBLE), tx_plain_numeric_value) IS NOT NULL THEN
        CASE
          WHEN (tx_value_token IS NOT NULL AND tx_tail_raw IS NULL) OR tx_plain_numeric_value IS NOT NULL THEN 'parsed_inferred_asset'
          ELSE 'parsed'
        END
      ELSE 'malformed'
    END AS tx_label_status,
    CASE
      WHEN from_label IS NULL THEN 'unlabeled'
      WHEN from_paren_body IS NOT NULL AND from_value_token IS NULL THEN 'malformed'
      WHEN from_types IS NOT NULL OR (from_counterparty_raw IS NOT NULL AND regexp_matches(from_counterparty_raw, '[A-Za-z]')) OR try_cast(replace(from_value_token, ',', '') AS DOUBLE) IS NOT NULL THEN
        CASE
          WHEN from_value_token IS NOT NULL AND from_tail_raw IS NULL THEN 'parsed_inferred_asset'
          ELSE 'parsed'
        END
      ELSE 'malformed'
    END AS from_label_status,
    CASE
      WHEN to_label IS NULL THEN 'unlabeled'
      WHEN to_paren_body IS NOT NULL AND to_value_token IS NULL THEN 'malformed'
      WHEN to_types IS NOT NULL OR (to_counterparty_raw IS NOT NULL AND regexp_matches(to_counterparty_raw, '[A-Za-z]')) OR try_cast(replace(to_value_token, ',', '') AS DOUBLE) IS NOT NULL THEN
        CASE
          WHEN to_value_token IS NOT NULL AND to_tail_raw IS NULL THEN 'parsed_inferred_asset'
          ELSE 'parsed'
        END
      ELSE 'malformed'
    END AS to_label_status,

    CASE
      WHEN ts IS NULL THEN 'missing'
      ELSE 'parsed'
    END AS time_status,
    CASE
      WHEN amount_value IS NULL THEN 'missing_value'
      WHEN asset IS NULL THEN 'missing_asset'
      ELSE 'parsed'
    END AS amount_status,
    CASE
      WHEN amount_usd_value IS NULL THEN 'missing'
      ELSE 'parsed'
    END AS usd_status,

    regexp_matches(lower(coalesce(tx_label_actions, '')), '(^|[/\\])theft($|[/\\])') AS tx_is_theft,
    regexp_matches(lower(coalesce(tx_label_actions, '')), '(^|[/\\])cc:[0-9]+:(in|out)($|[/\\])') AS tx_is_cross_chain,
    try_cast(regexp_extract(lower(coalesce(tx_label_actions, '')), '(^|[/\\])cc:([0-9]+):(in|out)($|[/\\])', 2) AS INTEGER) AS tx_cc_id,
    upper(nullif(regexp_extract(lower(coalesce(tx_label_actions, '')), '(^|[/\\])cc:([0-9]+):(in|out)($|[/\\])', 3), '')) AS tx_cc_direction
  FROM measured
), eligible AS (
  SELECT
    *,
    CASE
      WHEN tx_is_cross_chain AND format = 'qlue_utxo' THEN lower(coalesce(tx_cc_direction, ''))
      WHEN tx_is_cross_chain THEN 'transaction'
      ELSE NULL
    END AS cc_match_side,
    CASE
      WHEN NOT tx_is_cross_chain THEN FALSE
      WHEN format = 'qlue_utxo' THEN lower(coalesce(direction, '')) = lower(coalesce(tx_cc_direction, ''))
      ELSE TRUE
    END AS cc_match_eligible
  FROM normalized
), leg_context AS (
  SELECT
    *,
    count(*) FILTER (WHERE lower(coalesce(direction, '')) = 'in') OVER (PARTITION BY tx_hash) AS tx_input_leg_count,
    count(*) FILTER (WHERE lower(coalesce(direction, '')) = 'out') OVER (PARTITION BY tx_hash) AS tx_output_leg_count,
    regexp_matches(lower(coalesce(tx_label_actions, '')), '(^|[/\\])d($|[/\\])') AS action_has_deposit,
    regexp_matches(lower(coalesce(tx_label_actions, '')), '(^|[/\\])theft($|[/\\])') AS action_has_theft,
    regexp_matches(lower(coalesce(tx_label_actions, '')), '(^|[/\\])w($|[/\\])') AS action_has_withdrawal,
    regexp_matches(lower(coalesce(from_types, '')), '(^|[/\\])ve($|[/\\])') AS from_is_ve,
    regexp_matches(lower(coalesce(to_types, '')), '(^|[/\\])da($|[/\\])') AS to_is_da,
    regexp_matches(lower(coalesce(to_types, '')), '(^|[/\\])ta($|[/\\])') AS to_is_ta,
    lower(trim(coalesce(tx_label_counterparty, ''))) AS tx_counterparty_norm,
    lower(trim(coalesce(from_counterparty, ''))) AS from_counterparty_norm,
    lower(trim(coalesce(to_counterparty, ''))) AS to_counterparty_norm,
    lower(coalesce(from_label, '')) AS from_label_lower,
    lower(coalesce(to_label, '')) AS to_label_lower
  FROM eligible
), leg_resolution AS (
  SELECT
    *,
    CASE
      WHEN format <> 'qlue_utxo' THEN TRUE
      WHEN transfer_label IS NULL THEN TRUE
      WHEN tx_is_cross_chain THEN cc_match_eligible
      WHEN action_has_withdrawal AND lower(coalesce(direction, '')) = 'in' AND from_is_ve THEN TRUE
      WHEN action_has_withdrawal AND lower(coalesce(direction, '')) = 'in'
           AND tx_counterparty_norm <> ''
           AND (from_counterparty_norm = tx_counterparty_norm OR strpos(from_label_lower, tx_counterparty_norm) > 0) THEN TRUE
      WHEN action_has_withdrawal AND lower(coalesce(direction, '')) = 'in' AND tx_input_leg_count = 1 THEN TRUE
      WHEN action_has_deposit AND lower(coalesce(direction, '')) = 'out' AND to_is_da THEN TRUE
      WHEN action_has_theft AND lower(coalesce(direction, '')) = 'out' AND to_is_ta THEN TRUE
      WHEN (action_has_deposit OR action_has_theft) AND lower(coalesce(direction, '')) = 'out'
           AND tx_counterparty_norm <> ''
           AND (to_counterparty_norm = tx_counterparty_norm OR strpos(to_label_lower, tx_counterparty_norm) > 0) THEN TRUE
      WHEN (action_has_deposit OR action_has_theft) AND lower(coalesce(direction, '')) = 'out' AND tx_output_leg_count = 1 THEN TRUE
      WHEN lower(coalesce(direction, '')) = 'out'
           AND tx_counterparty_norm <> ''
           AND (to_counterparty_norm = tx_counterparty_norm OR strpos(to_label_lower, tx_counterparty_norm) > 0) THEN TRUE
      WHEN lower(coalesce(direction, '')) = 'out'
           AND tx_counterparty_norm = ''
           AND tx_output_leg_count = 1 THEN TRUE
      WHEN lower(coalesce(direction, '')) = 'in'
           AND tx_counterparty_norm <> ''
           AND (from_counterparty_norm = tx_counterparty_norm OR strpos(from_label_lower, tx_counterparty_norm) > 0)
           AND tx_output_leg_count = 0 THEN TRUE
      WHEN lower(coalesce(direction, '')) = 'in'
           AND tx_counterparty_norm = ''
           AND tx_input_leg_count = 1
           AND tx_output_leg_count = 0 THEN TRUE
      ELSE FALSE
    END AS tx_label_leg_applies,
    CASE
      WHEN format <> 'qlue_utxo' THEN 'account_row'
      WHEN transfer_label IS NULL THEN 'unlabeled_row'
      WHEN tx_is_cross_chain AND cc_match_eligible THEN 'cross_chain_side_match'
      WHEN tx_is_cross_chain THEN 'cross_chain_other_side'
      WHEN action_has_withdrawal AND lower(coalesce(direction, '')) = 'in' AND from_is_ve THEN 'withdrawal_from_service'
      WHEN action_has_withdrawal AND lower(coalesce(direction, '')) = 'in'
           AND tx_counterparty_norm <> ''
           AND (from_counterparty_norm = tx_counterparty_norm OR strpos(from_label_lower, tx_counterparty_norm) > 0) THEN 'withdrawal_counterparty_match'
      WHEN action_has_withdrawal AND lower(coalesce(direction, '')) = 'in' AND tx_input_leg_count = 1 THEN 'single_input_leg'
      WHEN action_has_deposit AND lower(coalesce(direction, '')) = 'out' AND to_is_da THEN 'deposit_to_da'
      WHEN action_has_theft AND lower(coalesce(direction, '')) = 'out' AND to_is_ta THEN 'theft_to_ta'
      WHEN (action_has_deposit OR action_has_theft) AND lower(coalesce(direction, '')) = 'out'
           AND tx_counterparty_norm <> ''
           AND (to_counterparty_norm = tx_counterparty_norm OR strpos(to_label_lower, tx_counterparty_norm) > 0) THEN 'output_counterparty_match'
      WHEN (action_has_deposit OR action_has_theft) AND lower(coalesce(direction, '')) = 'out' AND tx_output_leg_count = 1 THEN 'single_output_leg'
      WHEN lower(coalesce(direction, '')) = 'out'
           AND tx_counterparty_norm <> ''
           AND (to_counterparty_norm = tx_counterparty_norm OR strpos(to_label_lower, tx_counterparty_norm) > 0) THEN 'output_counterparty_match'
      WHEN lower(coalesce(direction, '')) = 'out'
           AND tx_counterparty_norm = ''
           AND tx_output_leg_count = 1 THEN 'single_output_leg'
      WHEN lower(coalesce(direction, '')) = 'in'
           AND tx_counterparty_norm <> ''
           AND (from_counterparty_norm = tx_counterparty_norm OR strpos(from_label_lower, tx_counterparty_norm) > 0)
           AND tx_output_leg_count = 0 THEN 'input_counterparty_match'
      WHEN lower(coalesce(direction, '')) = 'in'
           AND tx_counterparty_norm = ''
           AND tx_input_leg_count = 1
           AND tx_output_leg_count = 0 THEN 'single_input_leg'
      ELSE 'no_leg_match'
    END AS tx_label_leg_match_reason
  FROM leg_context
), applicable AS (
  SELECT
    *,
    sum(CASE WHEN tx_label_leg_applies THEN 1 ELSE 0 END) OVER (PARTITION BY tx_hash) AS tx_label_applicable_leg_count
  FROM leg_resolution
), theft_transactions AS (
  SELECT
    tx_hash,
    row_number() OVER (ORDER BY min(ts) NULLS LAST, tx_hash) AS theft_id
  FROM applicable
  WHERE tx_is_theft
    AND tx_hash IS NOT NULL
  GROUP BY tx_hash
), final AS (
  SELECT
    e.vendor,
    e.format,
    e.chain,
    e.ts,
    e.tx_hash,
    e.from_address,
    e.to_address,
    e.from_label,
    e.to_label,
    e.address_label,
    e.direction,
    e.asset,
    e.amount_value,
    e.amount_usd_value,
    e.transfer_label,
    t.theft_id,
    CASE
      WHEN e.tx_label_leg_applies THEN
        CASE
          WHEN e.amount_value IS NULL THEN e.tx_label_value
          WHEN e.tx_label_value IS NULL THEN e.amount_value
          ELSE LEAST(e.amount_value, e.tx_label_value)
        END
      WHEN e.transfer_label IS NULL THEN e.amount_value
      ELSE 0
    END AS stolen_amount_value,
    e.source_file,
    e.tx_label_actions,
    e.tx_label_counterparty,
    e.tx_label_value,
    e.tx_label_asset,
    e.tx_label_status,
    e.from_types,
    e.from_counterparty,
    e.from_dormant_value,
    e.from_dormant_asset,
    e.from_label_status,
    e.to_types,
    e.to_counterparty,
    e.to_dormant_value,
    e.to_dormant_asset,
    e.to_label_status,
    e.tx_is_theft,
    e.tx_is_cross_chain,
    e.tx_cc_id,
    e.tx_cc_direction,
    e.cc_match_side,
    e.cc_match_eligible,
    e.tx_input_leg_count,
    e.tx_output_leg_count,
    e.tx_label_leg_applies,
    e.tx_label_leg_match_reason,
    e.tx_label_applicable_leg_count,
    e.time_status,
    e.amount_status,
    e.usd_status
  FROM applicable e
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

CREATE OR REPLACE VIEW v_cross_chain_conflicts AS
WITH cc_rows AS (
  SELECT *
  FROM transactions
  WHERE tx_is_cross_chain
    AND tx_cc_id IS NOT NULL
), conflicts AS (
  SELECT
    tx_hash,
    count(*) AS cc_row_count,
    count(*) FILTER (WHERE cc_match_eligible) AS eligible_row_count,
    count(DISTINCT tx_cc_id) AS cc_id_count,
    count(DISTINCT tx_cc_direction) AS cc_direction_count,
    min(tx_cc_id) AS min_cc_id,
    max(tx_cc_id) AS max_cc_id,
    min(tx_cc_direction) AS min_cc_direction,
    max(tx_cc_direction) AS max_cc_direction
  FROM cc_rows
  GROUP BY tx_hash
)
SELECT
  *,
  CASE
    WHEN cc_id_count > 1 THEN 'multiple_cc_ids_per_tx_hash'
    WHEN cc_direction_count > 1 THEN 'multiple_cc_directions_per_tx_hash'
    WHEN eligible_row_count = 0 THEN 'no_eligible_cc_rows'
    ELSE 'ok'
  END AS cc_conflict_status
FROM conflicts
WHERE cc_id_count > 1
   OR cc_direction_count > 1
   OR eligible_row_count = 0;

CREATE OR REPLACE VIEW v_cross_chain_tx_legs AS
WITH cc_rows AS (
  SELECT *
  FROM transactions
  WHERE tx_is_cross_chain
    AND tx_cc_id IS NOT NULL
), conflicts AS (
  SELECT tx_hash
  FROM v_cross_chain_conflicts
), eligible_rows AS (
  SELECT *
  FROM cc_rows
  WHERE cc_match_eligible
    AND tx_hash NOT IN (SELECT tx_hash FROM conflicts)
)
SELECT
  tx_cc_id,
  tx_cc_direction,
  tx_hash,
  min(ts) AS ts,
  min(chain) AS chain,
  min(format) AS format,
  min(tx_label_counterparty) AS tx_label_counterparty,
  max(tx_label_value) AS tx_label_value,
  max(tx_label_asset) AS tx_label_asset,
  min(cc_match_side) AS cc_match_side,
  count(*) AS eligible_transfer_rows,
  sum(coalesce(amount_value, 0)) AS cc_match_amount_value,
  CASE
    WHEN count(*) FILTER (WHERE amount_usd_value IS NOT NULL) = 0 THEN NULL
    ELSE sum(coalesce(amount_usd_value, 0))
  END AS cc_match_amount_usd_value,
  min(asset) AS asset_example
FROM eligible_rows
GROUP BY tx_cc_id, tx_cc_direction, tx_hash;

CREATE OR REPLACE VIEW v_cross_chain_pairs AS
WITH legs AS (
  SELECT * FROM v_cross_chain_tx_legs
), side_counts AS (
  SELECT
    tx_cc_id,
    count(*) FILTER (WHERE tx_cc_direction = 'IN') AS in_tx_count,
    count(*) FILTER (WHERE tx_cc_direction = 'OUT') AS out_tx_count
  FROM legs
  GROUP BY tx_cc_id
), in_legs AS (
  SELECT * FROM legs WHERE tx_cc_direction = 'IN'
), out_legs AS (
  SELECT * FROM legs WHERE tx_cc_direction = 'OUT'
)
SELECT
  s.tx_cc_id,
  s.in_tx_count,
  s.out_tx_count,
  i.tx_hash AS in_tx_hash,
  i.chain AS in_chain,
  i.asset_example AS in_asset,
  i.cc_match_amount_value AS in_amount_value,
  i.cc_match_amount_usd_value AS in_amount_usd_value,
  i.tx_label_value AS in_label_value,
  i.tx_label_asset AS in_label_asset,
  coalesce(i.tx_label_value, i.cc_match_amount_value) AS in_effective_match_value,
  coalesce(i.tx_label_asset, i.asset_example) AS in_effective_match_asset,
  i.tx_label_counterparty AS in_counterparty,
  i.cc_match_side AS in_match_side,
  i.eligible_transfer_rows AS in_transfer_rows,
  i.ts AS in_ts,
  o.tx_hash AS out_tx_hash,
  o.chain AS out_chain,
  o.asset_example AS out_asset,
  o.cc_match_amount_value AS out_amount_value,
  o.cc_match_amount_usd_value AS out_amount_usd_value,
  o.tx_label_value AS out_label_value,
  o.tx_label_asset AS out_label_asset,
  coalesce(o.tx_label_value, o.cc_match_amount_value) AS out_effective_match_value,
  coalesce(o.tx_label_asset, o.asset_example) AS out_effective_match_asset,
  o.tx_label_counterparty AS out_counterparty,
  o.cc_match_side AS out_match_side,
  o.eligible_transfer_rows AS out_transfer_rows,
  o.ts AS out_ts,
  CASE
    WHEN s.in_tx_count = 0 THEN 'missing_in'
    WHEN s.out_tx_count = 0 THEN 'missing_out'
    WHEN s.in_tx_count > 1 AND s.out_tx_count > 1 THEN 'duplicate_in_and_out'
    WHEN s.in_tx_count > 1 THEN 'duplicate_in'
    WHEN s.out_tx_count > 1 THEN 'duplicate_out'
    ELSE 'paired'
  END AS cc_pair_status,
  CASE
    WHEN i.ts IS NULL OR o.ts IS NULL THEN 'missing_timestamp'
    WHEN o.ts < i.ts THEN 'out_before_in'
    WHEN date_diff('minute', i.ts, o.ts) > 720 THEN 'delta_gt_12h'
    ELSE 'ok'
  END AS cc_timing_status,
  CASE
    WHEN i.ts IS NULL OR o.ts IS NULL THEN NULL
    ELSE abs(date_diff('minute', i.ts, o.ts)) / 60.0
  END AS cc_timing_delta_hours
FROM side_counts s
LEFT JOIN in_legs i ON s.tx_cc_id = i.tx_cc_id AND s.in_tx_count = 1
LEFT JOIN out_legs o ON s.tx_cc_id = o.tx_cc_id AND s.out_tx_count = 1;

CREATE OR REPLACE VIEW v_issue_rows AS
WITH cc_conflicts AS (
  SELECT tx_hash, cc_conflict_status FROM v_cross_chain_conflicts
), cc_pair_warnings AS (
  SELECT in_tx_hash AS tx_hash, cc_timing_status
  FROM v_cross_chain_pairs
  WHERE cc_timing_status <> 'ok'
  UNION ALL
  SELECT out_tx_hash AS tx_hash, cc_timing_status
  FROM v_cross_chain_pairs
  WHERE cc_timing_status <> 'ok'
)
SELECT
  t.*,
  cc.cc_conflict_status,
  pw.cc_timing_status,
  trim(
    both '|' FROM concat(
      CASE WHEN tx_label_status = 'malformed' THEN 'tx_label_malformed|' ELSE '' END,
      CASE WHEN from_label_status = 'malformed' THEN 'from_label_malformed|' ELSE '' END,
      CASE WHEN to_label_status = 'malformed' THEN 'to_label_malformed|' ELSE '' END,
      CASE WHEN time_status <> 'parsed' THEN 'time_issue|' ELSE '' END,
      CASE WHEN amount_status <> 'parsed' THEN 'amount_issue|' ELSE '' END,
      CASE WHEN format = 'qlue_utxo'
             AND transfer_label IS NOT NULL
             AND tx_label_leg_applies = FALSE
             AND tx_label_applicable_leg_count = 0
        THEN 'tx_label_leg_unresolved|' ELSE '' END,
      CASE WHEN tx_label_value IS NOT NULL
             AND amount_value IS NOT NULL
             AND tx_label_leg_applies
             AND tx_label_value > amount_value
        THEN 'label_value_exceeds_amount|' ELSE '' END,
      CASE WHEN cc.cc_conflict_status IS NOT NULL THEN 'cross_chain_conflict|' ELSE '' END,
      CASE WHEN pw.cc_timing_status IS NOT NULL THEN 'cross_chain_timing_warning|' ELSE '' END
    )
  ) AS issue_flags
FROM transactions t
LEFT JOIN cc_conflicts cc USING (tx_hash)
LEFT JOIN cc_pair_warnings pw USING (tx_hash)
WHERE tx_label_status = 'malformed'
   OR from_label_status = 'malformed'
   OR to_label_status = 'malformed'
   OR time_status <> 'parsed'
   OR amount_status <> 'parsed'
   OR (format = 'qlue_utxo'
       AND transfer_label IS NOT NULL
       AND tx_label_leg_applies = FALSE
       AND tx_label_applicable_leg_count = 0)
   OR (tx_label_value IS NOT NULL
       AND amount_value IS NOT NULL
       AND tx_label_leg_applies
       AND tx_label_value > amount_value)
   OR cc.cc_conflict_status IS NOT NULL
   OR pw.cc_timing_status IS NOT NULL;

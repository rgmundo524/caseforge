PRAGMA threads=4;

-- Assumes normalize.py has already created v_stablecoins.
-- Final grain: one row per transfer leg.

CREATE OR REPLACE VIEW v_transfer_base AS
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
), parsed AS (
  SELECT
    *,
    trim(coalesce(from_label, '')) AS from_label_clean,
    trim(coalesce(to_label, '')) AS to_label_clean
  FROM base
), measured AS (
  SELECT
    *,
    nullif(trim(regexp_extract(from_label_clean, '^\[([^]]+)\]', 1)), '') AS from_types,
    nullif(trim(regexp_extract(to_label_clean, '^\[([^]]+)\]', 1)), '') AS to_types,

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

    nullif(trim(regexp_extract(from_label_clean, '\(([^)]*)\)\s*$', 1)), '') AS from_paren_body,
    nullif(trim(regexp_extract(to_label_clean, '\(([^)]*)\)\s*$', 1)), '') AS to_paren_body
  FROM parsed
), tokens AS (
  SELECT
    *,
    nullif(trim(regexp_extract(coalesce(from_paren_body, ''), '^([-+]?(?:[0-9][0-9,]*(?:\.[0-9]+)?|\.[0-9]+))', 0)), '') AS from_num_full,
    nullif(trim(regexp_extract(coalesce(from_paren_body, ''), '^([-+]?(?:[0-9][0-9,]*(?:\.[0-9]+)?|\.[0-9]+))', 1)), '') AS from_value_token,
    nullif(trim(regexp_extract(coalesce(to_paren_body, ''), '^([-+]?(?:[0-9][0-9,]*(?:\.[0-9]+)?|\.[0-9]+))', 0)), '') AS to_num_full,
    nullif(trim(regexp_extract(coalesce(to_paren_body, ''), '^([-+]?(?:[0-9][0-9,]*(?:\.[0-9]+)?|\.[0-9]+))', 1)), '') AS to_value_token
  FROM measured
), final AS (
  SELECT
    *,
    CASE
      WHEN from_num_full IS NULL THEN NULL
      ELSE nullif(trim(substr(coalesce(from_paren_body, ''), length(from_num_full) + 1)), '')
    END AS from_tail_raw,
    CASE
      WHEN to_num_full IS NULL THEN NULL
      ELSE nullif(trim(substr(coalesce(to_paren_body, ''), length(to_num_full) + 1)), '')
    END AS to_tail_raw
  FROM tokens
)
SELECT
  row_number() OVER (
    ORDER BY ts NULLS LAST, tx_hash, source_file, coalesce(direction, ''), coalesce(from_address, ''), coalesce(to_address, ''), coalesce(asset, ''), coalesce(amount_value, 0)
  ) AS transfer_row_id,
  CASE
    WHEN format = 'qlue_utxo' THEN 'utxo:' || coalesce(tx_hash, cast(row_number() OVER (
      ORDER BY ts NULLS LAST, tx_hash, source_file, coalesce(direction, ''), coalesce(from_address, ''), coalesce(to_address, ''), coalesce(asset, ''), coalesce(amount_value, 0)
    ) AS VARCHAR))
    ELSE 'row:' || cast(row_number() OVER (
      ORDER BY ts NULLS LAST, tx_hash, source_file, coalesce(direction, ''), coalesce(from_address, ''), coalesce(to_address, ''), coalesce(asset, ''), coalesce(amount_value, 0)
    ) AS VARCHAR)
  END AS row_label_owner_id,
  vendor,
  tx_model,
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
  amount_value,
  amount_usd_value,
  transfer_label,
  source_file,
  from_types,
  CASE
    WHEN from_counterparty_raw IS NOT NULL AND regexp_matches(from_counterparty_raw, '[A-Za-z]') THEN from_counterparty_raw
    ELSE NULL
  END AS from_counterparty,
  try_cast(replace(from_value_token, ',', '') AS DOUBLE) AS from_dormant_value,
  CASE
    WHEN from_value_token IS NULL THEN NULL
    WHEN from_tail_raw IS NULL THEN asset
    ELSE upper(from_tail_raw)
  END AS from_dormant_asset,
  CASE
    WHEN from_label IS NULL THEN 'unlabeled'
    WHEN from_paren_body IS NOT NULL AND from_value_token IS NULL THEN 'malformed'
    WHEN from_types IS NOT NULL
      OR (from_counterparty_raw IS NOT NULL AND regexp_matches(from_counterparty_raw, '[A-Za-z]'))
      OR try_cast(replace(from_value_token, ',', '') AS DOUBLE) IS NOT NULL
      THEN CASE
        WHEN from_value_token IS NOT NULL AND from_tail_raw IS NULL THEN 'parsed_inferred_asset'
        ELSE 'parsed'
      END
    ELSE 'malformed'
  END AS from_label_status,
  to_types,
  CASE
    WHEN to_counterparty_raw IS NOT NULL AND regexp_matches(to_counterparty_raw, '[A-Za-z]') THEN to_counterparty_raw
    ELSE NULL
  END AS to_counterparty,
  try_cast(replace(to_value_token, ',', '') AS DOUBLE) AS to_dormant_value,
  CASE
    WHEN to_value_token IS NULL THEN NULL
    WHEN to_tail_raw IS NULL THEN asset
    ELSE upper(to_tail_raw)
  END AS to_dormant_asset,
  CASE
    WHEN to_label IS NULL THEN 'unlabeled'
    WHEN to_paren_body IS NOT NULL AND to_value_token IS NULL THEN 'malformed'
    WHEN to_types IS NOT NULL
      OR (to_counterparty_raw IS NOT NULL AND regexp_matches(to_counterparty_raw, '[A-Za-z]'))
      OR try_cast(replace(to_value_token, ',', '') AS DOUBLE) IS NOT NULL
      THEN CASE
        WHEN to_value_token IS NOT NULL AND to_tail_raw IS NULL THEN 'parsed_inferred_asset'
        ELSE 'parsed'
      END
    ELSE 'malformed'
  END AS to_label_status,
  CASE WHEN ts IS NULL THEN 'missing' ELSE 'parsed' END AS time_status,
  CASE
    WHEN amount_value IS NULL THEN 'missing_value'
    WHEN asset IS NULL THEN 'missing_asset'
    ELSE 'parsed'
  END AS amount_status,
  CASE WHEN amount_usd_value IS NULL THEN 'missing' ELSE 'parsed' END AS usd_status,
  lower(trim(coalesce(CASE
    WHEN from_counterparty_raw IS NOT NULL AND regexp_matches(from_counterparty_raw, '[A-Za-z]') THEN from_counterparty_raw
    ELSE NULL
  END, ''))) AS from_counterparty_norm,
  lower(trim(coalesce(CASE
    WHEN to_counterparty_raw IS NOT NULL AND regexp_matches(to_counterparty_raw, '[A-Za-z]') THEN to_counterparty_raw
    ELSE NULL
  END, ''))) AS to_counterparty_norm,
  lower(coalesce(from_label, '')) AS from_label_lower,
  lower(coalesce(to_label, '')) AS to_label_lower,
  count(*) FILTER (WHERE lower(coalesce(direction, '')) = 'in') OVER (PARTITION BY tx_hash) AS tx_input_leg_count,
  count(*) FILTER (WHERE lower(coalesce(direction, '')) = 'out') OVER (PARTITION BY tx_hash) AS tx_output_leg_count,
  regexp_matches(lower(coalesce(from_types, '')), '(^|[/\\])ve($|[/\\])') AS from_is_ve,
  regexp_matches(lower(coalesce(to_types, '')), '(^|[/\\])da($|[/\\])') AS to_is_da,
  regexp_matches(lower(coalesce(to_types, '')), '(^|[/\\])ta($|[/\\])') AS to_is_ta
FROM final;

CREATE OR REPLACE VIEW v_tx_label_entries AS
WITH non_utxo AS (
  SELECT
    row_label_owner_id AS label_owner_id,
    transfer_row_id AS owner_transfer_row_id,
    tx_hash,
    format,
    chain,
    asset AS asset_context,
    transfer_label AS entry_raw
  FROM v_transfer_base
  WHERE transfer_label IS NOT NULL
    AND format <> 'qlue_utxo'
), utxo_source AS (
  SELECT
    'utxo:' || coalesce(tx_hash, cast(min(transfer_row_id) AS VARCHAR)) AS label_owner_id,
    NULL::BIGINT AS owner_transfer_row_id,
    tx_hash,
    format,
    min(chain) AS chain,
    min(asset) AS asset_context,
    transfer_label
  FROM v_transfer_base
  WHERE transfer_label IS NOT NULL
    AND format = 'qlue_utxo'
  GROUP BY tx_hash, format, transfer_label
), utxo_split AS (
  SELECT
    label_owner_id,
    owner_transfer_row_id,
    tx_hash,
    format,
    chain,
    asset_context,
    nullif(trim(entry_raw), '') AS entry_raw
  FROM utxo_source,
       UNNEST(regexp_split_to_array(transfer_label, ',\s+')) AS t(entry_raw)
), owner_union AS (
  SELECT * FROM non_utxo
  UNION ALL
  SELECT * FROM utxo_split
), cleaned AS (
  SELECT
    *,
    row_number() OVER (ORDER BY label_owner_id, coalesce(entry_raw, '')) AS entry_id,
    row_number() OVER (PARTITION BY label_owner_id ORDER BY coalesce(entry_raw, '')) AS entry_index,
    trim(coalesce(entry_raw, '')) AS entry_clean
  FROM owner_union
  WHERE entry_raw IS NOT NULL
    AND trim(entry_raw) <> ''
), parsed AS (
  SELECT
    *,
    nullif(trim(regexp_extract(entry_clean, '^\[([^]]+)\]', 1)), '') AS entry_actions,
    nullif(
      trim(
        regexp_replace(
          trim(regexp_replace(entry_clean, '^\[[^]]+\]\s*', '')),
          '\s*\([^)]*\)\s*$',
          ''
        )
      ),
      ''
    ) AS entry_counterparty_raw,
    nullif(trim(regexp_extract(entry_clean, '\(([^)]*)\)\s*$', 1)), '') AS entry_paren_body,
    CASE
      WHEN regexp_matches(entry_clean, '^\s*[-+]?(?:[0-9][0-9,]*(?:\.[0-9]+)?|\.[0-9]+)\s*$')
        THEN nullif(trim(entry_clean), '')
      ELSE NULL
    END AS entry_plain_numeric_token
  FROM cleaned
), measured AS (
  SELECT
    *,
    nullif(trim(regexp_extract(coalesce(entry_paren_body, ''), '^([-+]?(?:[0-9][0-9,]*(?:\.[0-9]+)?|\.[0-9]+))', 0)), '') AS entry_num_full,
    nullif(trim(regexp_extract(coalesce(entry_paren_body, ''), '^([-+]?(?:[0-9][0-9,]*(?:\.[0-9]+)?|\.[0-9]+))', 1)), '') AS entry_value_token,
    try_cast(replace(entry_plain_numeric_token, ',', '') AS DOUBLE) AS entry_plain_numeric_value
  FROM parsed
), normalized AS (
  SELECT
    *,
    CASE
      WHEN entry_num_full IS NULL THEN NULL
      ELSE nullif(trim(substr(coalesce(entry_paren_body, ''), length(entry_num_full) + 1)), '')
    END AS entry_tail_raw
  FROM measured
)
SELECT
  entry_id,
  entry_index,
  label_owner_id,
  owner_transfer_row_id,
  tx_hash,
  format,
  chain,
  entry_raw,
  entry_actions,
  CASE
    WHEN entry_counterparty_raw IS NOT NULL AND regexp_matches(entry_counterparty_raw, '[A-Za-z]') THEN entry_counterparty_raw
    ELSE NULL
  END AS entry_counterparty,
  lower(trim(coalesce(CASE
    WHEN entry_counterparty_raw IS NOT NULL AND regexp_matches(entry_counterparty_raw, '[A-Za-z]') THEN entry_counterparty_raw
    ELSE NULL
  END, ''))) AS entry_counterparty_norm,
  coalesce(
    try_cast(replace(entry_value_token, ',', '') AS DOUBLE),
    entry_plain_numeric_value
  ) AS entry_value,
  CASE
    WHEN entry_value_token IS NOT NULL THEN
      CASE
        WHEN entry_tail_raw IS NULL THEN asset_context
        ELSE upper(entry_tail_raw)
      END
    WHEN entry_plain_numeric_value IS NOT NULL THEN asset_context
    ELSE NULL
  END AS entry_asset,
  entry_paren_body,
  CASE
    WHEN entry_raw IS NULL THEN 'unlabeled'
    WHEN entry_paren_body IS NOT NULL AND entry_value_token IS NULL AND entry_plain_numeric_value IS NULL THEN 'malformed'
    WHEN entry_plain_numeric_value IS NOT NULL THEN 'parsed_inferred_asset'
    WHEN entry_actions IS NOT NULL
      OR (entry_counterparty_raw IS NOT NULL AND regexp_matches(entry_counterparty_raw, '[A-Za-z]'))
      OR coalesce(try_cast(replace(entry_value_token, ',', '') AS DOUBLE), entry_plain_numeric_value) IS NOT NULL
      THEN CASE
        WHEN (entry_value_token IS NOT NULL AND entry_tail_raw IS NULL) OR entry_plain_numeric_value IS NOT NULL THEN 'parsed_inferred_asset'
        ELSE 'parsed'
      END
    ELSE 'malformed'
  END AS entry_status,
  regexp_matches(lower(coalesce(entry_actions, '')), '(^|[/\\])d($|[/\\])') AS entry_action_has_deposit,
  regexp_matches(lower(coalesce(entry_actions, '')), '(^|[/\\])w($|[/\\])') AS entry_action_has_withdrawal,
  regexp_matches(lower(coalesce(entry_actions, '')), '(^|[/\\])theft($|[/\\])') AS entry_action_has_theft,
  regexp_matches(lower(coalesce(entry_actions, '')), '(^|[/\\])cc:[0-9]+:(in|out)($|[/\\])') AS entry_is_cross_chain,
  try_cast(regexp_extract(lower(coalesce(entry_actions, '')), '(^|[/\\])cc:([0-9]+):(in|out)($|[/\\])', 2) AS INTEGER) AS entry_cc_id,
  upper(nullif(regexp_extract(lower(coalesce(entry_actions, '')), '(^|[/\\])cc:([0-9]+):(in|out)($|[/\\])', 3), '')) AS entry_cc_direction,
  CASE
    WHEN format = 'qlue_utxo'
      AND regexp_matches(lower(coalesce(entry_actions, '')), '(^|[/\\])cc:[0-9]+:(in|out)($|[/\\])')
      THEN 'utxo_side'
    ELSE 'leg'
  END AS entry_scope,
  CASE
    WHEN format = 'qlue_utxo'
      AND regexp_matches(lower(coalesce(entry_actions, '')), '(^|[/\\])cc:[0-9]+:(in|out)($|[/\\])')
      THEN lower(nullif(regexp_extract(lower(coalesce(entry_actions, '')), '(^|[/\\])cc:([0-9]+):(in|out)($|[/\\])', 3), ''))
    WHEN regexp_matches(lower(coalesce(entry_actions, '')), '(^|[/\\])w($|[/\\])')
      THEN 'in'
    ELSE 'out'
  END AS entry_side_hint
FROM normalized;

CREATE OR REPLACE VIEW v_tx_label_entry_candidates AS
WITH candidates AS (
  SELECT
    e.*,
    b.transfer_row_id,
    b.direction,
    b.amount_value,
    b.amount_usd_value,
    b.asset,
    b.from_label,
    b.to_label,
    b.from_types,
    b.to_types,
    b.from_counterparty,
    b.to_counterparty,
    b.from_counterparty_norm,
    b.to_counterparty_norm,
    b.from_label_lower,
    b.to_label_lower,
    b.from_is_ve,
    b.to_is_da,
    b.to_is_ta,
    b.tx_input_leg_count,
    b.tx_output_leg_count,
    CASE
      WHEN e.owner_transfer_row_id IS NOT NULL THEN TRUE
      ELSE FALSE
    END AS owner_row_match
  FROM v_tx_label_entries e
  JOIN v_transfer_base b
    ON (
      (e.owner_transfer_row_id IS NOT NULL AND b.transfer_row_id = e.owner_transfer_row_id)
      OR (e.owner_transfer_row_id IS NULL AND b.tx_hash = e.tx_hash)
    )
), scored AS (
  SELECT
    *,
    CASE
      WHEN owner_row_match THEN TRUE
      WHEN entry_scope = 'utxo_side' THEN lower(coalesce(direction, '')) = lower(coalesce(entry_cc_direction, ''))
      ELSE lower(coalesce(direction, '')) = lower(coalesce(entry_side_hint, ''))
    END AS direction_match,
    CASE
      WHEN entry_scope <> 'leg' THEN FALSE
      WHEN lower(coalesce(entry_side_hint, '')) = 'out'
        THEN entry_counterparty_norm <> ''
         AND (to_counterparty_norm = entry_counterparty_norm OR strpos(to_label_lower, entry_counterparty_norm) > 0)
      WHEN lower(coalesce(entry_side_hint, '')) = 'in'
        THEN entry_counterparty_norm <> ''
         AND (from_counterparty_norm = entry_counterparty_norm OR strpos(from_label_lower, entry_counterparty_norm) > 0)
      ELSE FALSE
    END AS counterparty_match,
    CASE
      WHEN entry_scope <> 'leg' THEN FALSE
      WHEN lower(coalesce(entry_side_hint, '')) = 'out' AND entry_action_has_deposit AND to_is_da THEN TRUE
      WHEN lower(coalesce(entry_side_hint, '')) = 'out' AND entry_action_has_theft AND to_is_ta THEN TRUE
      WHEN lower(coalesce(entry_side_hint, '')) = 'in' AND entry_action_has_withdrawal AND from_is_ve THEN TRUE
      ELSE FALSE
    END AS type_match,
    CASE
      WHEN entry_scope <> 'leg' THEN FALSE
      WHEN entry_value IS NULL OR amount_value IS NULL THEN FALSE
      ELSE abs(entry_value - amount_value) <= greatest(abs(amount_value), 1.0) * 1e-9
    END AS value_match,
    CASE
      WHEN entry_scope <> 'leg' THEN FALSE
      WHEN lower(coalesce(entry_side_hint, '')) = 'out' THEN tx_output_leg_count = 1
      WHEN lower(coalesce(entry_side_hint, '')) = 'in'  THEN tx_input_leg_count = 1
      ELSE FALSE
    END AS single_side_leg,
    CASE
      WHEN entry_asset IS NULL THEN TRUE
      ELSE upper(entry_asset) = asset
    END AS asset_match
  FROM candidates
), ranked AS (
  SELECT
    *,
    CASE
      WHEN owner_row_match THEN 1000
      WHEN entry_scope = 'utxo_side' AND direction_match THEN 800
      WHEN entry_scope = 'utxo_side' THEN NULL
      WHEN NOT direction_match OR NOT asset_match THEN NULL
      ELSE 100
        + CASE WHEN counterparty_match THEN 60 ELSE 0 END
        + CASE WHEN type_match THEN 25 ELSE 0 END
        + CASE WHEN value_match THEN 20 ELSE 0 END
        + CASE WHEN single_side_leg THEN 5 ELSE 0 END
    END AS candidate_score,
    CASE
      WHEN owner_row_match THEN 'account_owner_row'
      WHEN entry_scope = 'utxo_side' AND direction_match THEN 'cross_chain_side_match'
      WHEN entry_scope = 'utxo_side' THEN 'cross_chain_wrong_side'
      WHEN NOT direction_match THEN 'wrong_direction'
      WHEN NOT asset_match THEN 'asset_mismatch'
      WHEN counterparty_match AND lower(coalesce(entry_side_hint, '')) = 'out' THEN 'output_counterparty_match'
      WHEN counterparty_match AND lower(coalesce(entry_side_hint, '')) = 'in' THEN 'input_counterparty_match'
      WHEN type_match AND entry_action_has_deposit THEN 'deposit_type_match'
      WHEN type_match AND entry_action_has_theft THEN 'theft_type_match'
      WHEN type_match AND entry_action_has_withdrawal THEN 'withdrawal_type_match'
      WHEN value_match AND lower(coalesce(entry_side_hint, '')) = 'out' THEN 'output_value_match'
      WHEN value_match AND lower(coalesce(entry_side_hint, '')) = 'in' THEN 'input_value_match'
      WHEN single_side_leg AND lower(coalesce(entry_side_hint, '')) = 'out' THEN 'single_output_leg'
      WHEN single_side_leg AND lower(coalesce(entry_side_hint, '')) = 'in' THEN 'single_input_leg'
      ELSE 'direction_only'
    END AS candidate_reason
  FROM scored
), bested AS (
  SELECT
    *,
    max(candidate_score) OVER (PARTITION BY entry_id) AS best_score
  FROM ranked
), counted AS (
  SELECT
    *,
    count(*) FILTER (WHERE candidate_score = best_score) OVER (PARTITION BY entry_id) AS best_score_candidate_count
  FROM bested
)
SELECT
  *,
  CASE
    WHEN entry_status = 'malformed' THEN 'malformed_entry'
    WHEN candidate_score IS NULL THEN 'not_candidate'
    WHEN owner_row_match THEN 'assigned'
    WHEN entry_scope = 'utxo_side' THEN 'assigned'
    WHEN best_score IS NULL THEN 'unmatched'
    WHEN candidate_score = best_score AND best_score_candidate_count = 1 THEN 'assigned'
    WHEN candidate_score = best_score AND best_score_candidate_count > 1 THEN 'ambiguous'
    ELSE 'not_selected'
  END AS assignment_status
FROM counted;

CREATE OR REPLACE VIEW v_tx_label_entry_resolution AS
SELECT
  e.entry_id,
  e.entry_index,
  e.label_owner_id,
  e.owner_transfer_row_id,
  e.tx_hash,
  e.format,
  e.chain,
  e.entry_raw,
  e.entry_actions,
  e.entry_counterparty,
  e.entry_value,
  e.entry_asset,
  e.entry_status,
  e.entry_scope,
  e.entry_is_cross_chain,
  e.entry_cc_id,
  e.entry_cc_direction,
  e.entry_side_hint,
  count(*) FILTER (WHERE c.candidate_score IS NOT NULL) AS candidate_row_count,
  count(*) FILTER (WHERE c.assignment_status = 'assigned') AS assigned_row_count,
  count(*) FILTER (WHERE c.assignment_status = 'ambiguous') AS ambiguous_row_count,
  CASE
    WHEN e.entry_status = 'malformed' THEN 'malformed'
    WHEN count(*) FILTER (WHERE c.assignment_status = 'assigned') > 0 THEN 'assigned'
    WHEN count(*) FILTER (WHERE c.assignment_status = 'ambiguous') > 0 THEN 'ambiguous'
    WHEN count(*) FILTER (WHERE c.candidate_score IS NOT NULL) = 0 THEN 'unmatched'
    ELSE 'unresolved'
  END AS entry_resolution_status
FROM v_tx_label_entries e
LEFT JOIN v_tx_label_entry_candidates c USING (entry_id)
GROUP BY
  e.entry_id,
  e.entry_index,
  e.label_owner_id,
  e.owner_transfer_row_id,
  e.tx_hash,
  e.format,
  e.chain,
  e.entry_raw,
  e.entry_actions,
  e.entry_counterparty,
  e.entry_value,
  e.entry_asset,
  e.entry_status,
  e.entry_scope,
  e.entry_is_cross_chain,
  e.entry_cc_id,
  e.entry_cc_direction,
  e.entry_side_hint;

CREATE OR REPLACE VIEW v_tx_label_entry_assignments AS
WITH assigned AS (
  SELECT *
  FROM v_tx_label_entry_candidates
  WHERE assignment_status = 'assigned'
), side_totals AS (
  SELECT
    entry_id,
    sum(coalesce(amount_value, 0)) AS side_total_amount_value
  FROM assigned
  WHERE entry_scope = 'utxo_side'
  GROUP BY entry_id
)
SELECT
  a.entry_id,
  a.entry_index,
  a.label_owner_id,
  a.tx_hash,
  a.transfer_row_id,
  a.entry_raw,
  a.entry_scope,
  a.entry_actions,
  a.entry_counterparty,
  a.entry_value,
  a.entry_asset,
  a.entry_status,
  a.entry_is_cross_chain,
  a.entry_cc_id,
  a.entry_cc_direction,
  a.entry_side_hint,
  a.candidate_reason AS assignment_reason,
  a.candidate_score,
  CASE
    WHEN a.entry_scope = 'utxo_side' THEN coalesce(s.side_total_amount_value, a.amount_value)
    ELSE a.amount_value
  END AS assignment_capacity_value,
  CASE
    WHEN a.entry_scope = 'utxo_side' AND a.entry_value IS NOT NULL AND s.side_total_amount_value IS NOT NULL
      THEN a.entry_value > s.side_total_amount_value
    WHEN a.entry_scope <> 'utxo_side' AND a.entry_value IS NOT NULL AND a.amount_value IS NOT NULL
      THEN a.entry_value > a.amount_value
    ELSE FALSE
  END AS entry_value_exceeds_capacity,
  CASE
    WHEN a.entry_scope = 'utxo_side' THEN
      CASE
        WHEN s.side_total_amount_value IS NULL OR s.side_total_amount_value = 0 OR a.amount_value IS NULL THEN NULL
        ELSE LEAST(coalesce(a.entry_value, s.side_total_amount_value), s.side_total_amount_value) * a.amount_value / s.side_total_amount_value
      END
    ELSE
      CASE
        WHEN a.amount_value IS NULL THEN a.entry_value
        WHEN a.entry_value IS NULL THEN a.amount_value
        ELSE LEAST(a.amount_value, a.entry_value)
      END
  END AS allocated_stolen_amount_value
FROM assigned a
LEFT JOIN side_totals s USING (entry_id);

CREATE OR REPLACE VIEW v_tx_label_owner_summary AS
SELECT
  label_owner_id,
  count(*) AS tx_label_entry_count,
  count(*) FILTER (WHERE entry_resolution_status = 'assigned') AS tx_label_resolved_entry_count,
  count(*) FILTER (WHERE entry_resolution_status = 'ambiguous') AS tx_label_ambiguous_entry_count,
  count(*) FILTER (WHERE entry_resolution_status = 'unmatched') AS tx_label_unmatched_entry_count,
  count(*) FILTER (WHERE entry_resolution_status = 'malformed') AS tx_label_malformed_entry_count
FROM v_tx_label_entry_resolution
GROUP BY label_owner_id;

CREATE OR REPLACE VIEW v_transfers AS
WITH row_assignment_totals AS (
  SELECT
    transfer_row_id,
    count(*) AS tx_label_assigned_entry_count,
    sum(coalesce(allocated_stolen_amount_value, 0)) AS assigned_stolen_amount_value_raw,
    max(CASE WHEN entry_is_cross_chain THEN 1 ELSE 0 END) = 1 AS tx_is_cross_chain,
    max(CASE WHEN regexp_matches(lower(coalesce(entry_actions, '')), '(^|[/\\])theft($|[/\\])') THEN 1 ELSE 0 END) = 1 AS tx_is_theft,
    min(entry_cc_id) FILTER (WHERE entry_is_cross_chain) AS min_cc_id,
    max(entry_cc_id) FILTER (WHERE entry_is_cross_chain) AS max_cc_id,
    min(entry_cc_direction) FILTER (WHERE entry_is_cross_chain) AS min_cc_direction,
    max(entry_cc_direction) FILTER (WHERE entry_is_cross_chain) AS max_cc_direction,
    max(CASE WHEN entry_value_exceeds_capacity THEN 1 ELSE 0 END) = 1 AS any_entry_value_exceeds_capacity
  FROM v_tx_label_entry_assignments
  GROUP BY transfer_row_id
), primary_assignment AS (
  SELECT
    transfer_row_id,
    entry_id,
    entry_raw,
    entry_scope,
    entry_actions,
    entry_counterparty,
    entry_value,
    entry_asset,
    entry_status,
    assignment_reason,
    candidate_score,
    row_number() OVER (
      PARTITION BY transfer_row_id
      ORDER BY
        CASE entry_scope WHEN 'leg' THEN 3 WHEN 'utxo_side' THEN 2 ELSE 1 END DESC,
        candidate_score DESC,
        entry_id
    ) AS rn
  FROM v_tx_label_entry_assignments
), chosen_primary AS (
  SELECT *
  FROM primary_assignment
  WHERE rn = 1
), tx_assignment_counts AS (
  SELECT
    tx_hash,
    count(DISTINCT transfer_row_id) AS tx_label_applicable_leg_count
  FROM v_tx_label_entry_assignments
  GROUP BY tx_hash
), theft_transactions AS (
  SELECT
    tx_hash,
    row_number() OVER (ORDER BY min(ts) NULLS LAST, tx_hash) AS theft_id
  FROM (
    SELECT DISTINCT b.tx_hash, b.ts
    FROM v_transfer_base b
    JOIN v_tx_label_entry_assignments a ON b.transfer_row_id = a.transfer_row_id
    WHERE regexp_matches(lower(coalesce(a.entry_actions, '')), '(^|[/\\])theft($|[/\\])')
  ) t
  GROUP BY tx_hash
)
SELECT
  b.transfer_row_id,
  b.row_label_owner_id,
  b.vendor,
  b.format,
  b.chain,
  b.ts,
  b.tx_hash,
  b.from_address,
  b.to_address,
  b.from_label,
  b.to_label,
  b.address_label,
  b.direction,
  b.asset,
  b.amount_value,
  b.amount_usd_value,
  b.transfer_label,
  t.theft_id,
  CASE
    WHEN coalesce(r.tx_label_assigned_entry_count, 0) > 0 THEN
      CASE
        WHEN b.amount_value IS NULL THEN r.assigned_stolen_amount_value_raw
        ELSE LEAST(b.amount_value, r.assigned_stolen_amount_value_raw)
      END
    WHEN b.transfer_label IS NULL THEN b.amount_value
    ELSE 0
  END AS stolen_amount_value,
  b.source_file,
  p.entry_raw AS tx_label_entry_raw,
  p.entry_scope AS tx_label_scope,
  p.entry_actions AS tx_label_actions,
  p.entry_counterparty AS tx_label_counterparty,
  p.entry_value AS tx_label_value,
  p.entry_asset AS tx_label_asset,
  CASE
    WHEN p.entry_id IS NOT NULL THEN p.entry_status
    WHEN b.transfer_label IS NULL THEN 'unlabeled'
    WHEN coalesce(o.tx_label_malformed_entry_count, 0) > 0 AND coalesce(o.tx_label_resolved_entry_count, 0) = 0 THEN 'malformed'
    WHEN coalesce(o.tx_label_ambiguous_entry_count, 0) > 0 OR coalesce(o.tx_label_unmatched_entry_count, 0) > 0 THEN 'unresolved'
    WHEN coalesce(o.tx_label_resolved_entry_count, 0) > 0 THEN 'not_applicable_to_leg'
    ELSE 'unlabeled'
  END AS tx_label_status,
  CASE
    WHEN b.transfer_label IS NULL THEN 'no_tx_label'
    WHEN coalesce(r.tx_label_assigned_entry_count, 0) > 0 THEN 'applied'
    WHEN coalesce(o.tx_label_ambiguous_entry_count, 0) > 0 THEN 'ambiguous'
    WHEN coalesce(o.tx_label_unmatched_entry_count, 0) > 0 THEN 'unmatched'
    WHEN coalesce(o.tx_label_malformed_entry_count, 0) > 0 THEN 'malformed'
    WHEN coalesce(o.tx_label_resolved_entry_count, 0) > 0 THEN 'not_applicable_to_leg'
    ELSE 'unassigned'
  END AS tx_label_assignment_status,
  coalesce(o.tx_label_entry_count, 0) AS tx_label_entry_count,
  coalesce(r.tx_label_assigned_entry_count, 0) AS tx_label_assigned_entry_count,
  greatest(coalesce(r.tx_label_assigned_entry_count, 0) - 1, 0) AS tx_label_additional_entry_count,
  b.from_types,
  b.from_counterparty,
  b.from_dormant_value,
  b.from_dormant_asset,
  b.from_label_status,
  b.to_types,
  b.to_counterparty,
  b.to_dormant_value,
  b.to_dormant_asset,
  b.to_label_status,
  coalesce(r.tx_is_theft, FALSE) AS tx_is_theft,
  coalesce(r.tx_is_cross_chain, FALSE) AS tx_is_cross_chain,
  CASE
    WHEN coalesce(r.tx_is_cross_chain, FALSE) AND r.min_cc_id = r.max_cc_id THEN r.min_cc_id
    ELSE NULL
  END AS tx_cc_id,
  CASE
    WHEN coalesce(r.tx_is_cross_chain, FALSE) AND r.min_cc_direction = r.max_cc_direction THEN r.min_cc_direction
    ELSE NULL
  END AS tx_cc_direction,
  CASE
    WHEN coalesce(r.tx_is_cross_chain, FALSE) AND b.format = 'qlue_utxo' THEN lower(coalesce(b.direction, ''))
    WHEN coalesce(r.tx_is_cross_chain, FALSE) THEN 'transaction'
    ELSE NULL
  END AS cc_match_side,
  coalesce(r.tx_is_cross_chain, FALSE) AS cc_match_eligible,
  b.tx_input_leg_count,
  b.tx_output_leg_count,
  coalesce(r.tx_label_assigned_entry_count, 0) > 0 AS tx_label_leg_applies,
  coalesce(p.assignment_reason, 'no_assigned_entry') AS tx_label_leg_match_reason,
  coalesce(x.tx_label_applicable_leg_count, 0) AS tx_label_applicable_leg_count,
  b.time_status,
  b.amount_status,
  b.usd_status,
  coalesce(r.any_entry_value_exceeds_capacity, FALSE) AS tx_label_value_exceeds_capacity
FROM v_transfer_base b
LEFT JOIN row_assignment_totals r USING (transfer_row_id)
LEFT JOIN chosen_primary p ON b.transfer_row_id = p.transfer_row_id
LEFT JOIN v_tx_label_owner_summary o ON b.row_label_owner_id = o.label_owner_id
LEFT JOIN tx_assignment_counts x USING (tx_hash)
LEFT JOIN theft_transactions t USING (tx_hash);

CREATE OR REPLACE VIEW transactions AS
SELECT
  *,
  CASE
    WHEN amount_value IS NULL OR amount_usd_value IS NULL OR amount_value = 0 THEN NULL
    ELSE LEAST(amount_usd_value, amount_usd_value * (stolen_amount_value / amount_value))
  END AS stolen_amount_usd_value
FROM v_transfers;

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
  min(tx_label_scope) AS tx_label_scope,
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
  i.tx_label_scope AS in_label_scope,
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
  o.tx_label_scope AS out_label_scope,
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
      CASE WHEN tx_label_status = 'unresolved' THEN 'tx_label_unresolved|' ELSE '' END,
      CASE WHEN tx_label_assignment_status = 'ambiguous' THEN 'tx_label_ambiguous|' ELSE '' END,
      CASE WHEN tx_label_assignment_status = 'unmatched' THEN 'tx_label_unmatched|' ELSE '' END,
      CASE WHEN tx_label_assigned_entry_count > 1 THEN 'multiple_tx_label_entries_assigned|' ELSE '' END,
      CASE WHEN tx_label_value_exceeds_capacity THEN 'label_value_exceeds_capacity|' ELSE '' END,
      CASE WHEN from_label_status = 'malformed' THEN 'from_label_malformed|' ELSE '' END,
      CASE WHEN to_label_status = 'malformed' THEN 'to_label_malformed|' ELSE '' END,
      CASE WHEN time_status <> 'parsed' THEN 'time_issue|' ELSE '' END,
      CASE WHEN amount_status <> 'parsed' THEN 'amount_issue|' ELSE '' END,
      CASE WHEN cc.cc_conflict_status IS NOT NULL THEN 'cross_chain_conflict|' ELSE '' END,
      CASE WHEN pw.cc_timing_status IS NOT NULL THEN 'cross_chain_timing_warning|' ELSE '' END
    )
  ) AS issue_flags
FROM transactions t
LEFT JOIN cc_conflicts cc USING (tx_hash)
LEFT JOIN cc_pair_warnings pw USING (tx_hash)
WHERE tx_label_status IN ('malformed', 'unresolved')
   OR tx_label_assignment_status IN ('ambiguous', 'unmatched')
   OR tx_label_assigned_entry_count > 1
   OR tx_label_value_exceeds_capacity
   OR from_label_status = 'malformed'
   OR to_label_status = 'malformed'
   OR time_status <> 'parsed'
   OR amount_status <> 'parsed'
   OR cc.cc_conflict_status IS NOT NULL
   OR pw.cc_timing_status IS NOT NULL;

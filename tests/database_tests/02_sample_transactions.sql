-- File: 02_sample_transactions.sql
select
  ts,
  chain,
  tx_hash,
  direction,
  transfer_label,
  tx_label_actions,
  tx_label_counterparty,
  tx_label_value,
  tx_label_asset,
  tx_label_status,
  tx_label_leg_applies,
  tx_label_leg_match_reason,
  tx_label_applicable_leg_count,
  from_label,
  to_label,
  from_types,
  to_types,
  asset,
  amount_value,
  amount_usd_value,
  stolen_amount_value,
  stolen_amount_usd_value,
  tx_is_theft,
  tx_is_cross_chain,
  tx_cc_id,
  tx_cc_direction,
  cc_match_side,
  cc_match_eligible,
  source_file
from transactions
order by ts nulls last, tx_hash, direction nulls first
limit 100;

-- File: 02_sample_transactions.sql
select
  transfer_row_id,
  tx_hash,
  direction,
  asset,
  amount_value,
  amount_usd_value,
  transfer_label,
  tx_label_entry_raw,
  tx_label_scope,
  tx_label_actions,
  tx_label_counterparty,
  tx_label_value,
  tx_label_asset,
  tx_label_status,
  tx_label_assignment_status,
  tx_label_entry_count,
  tx_label_assigned_entry_count,
  tx_label_leg_applies,
  tx_label_leg_match_reason,
  from_label,
  to_label,
  stolen_amount_value,
  source_file
from transactions
order by ts nulls last, tx_hash, transfer_row_id
limit 50;

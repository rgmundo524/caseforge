-- File: 35_utxo_label_leg_resolution_check.sql
select
  transfer_row_id,
  tx_hash,
  direction,
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
  tx_label_applicable_leg_count,
  to_label,
  from_label,
  amount_value,
  stolen_amount_value
from transactions
where format = 'qlue_utxo'
  and transfer_label is not null
order by ts nulls last, tx_hash, transfer_row_id
limit 300;

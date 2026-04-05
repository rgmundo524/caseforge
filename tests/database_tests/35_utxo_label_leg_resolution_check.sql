-- File: 35_utxo_label_leg_resolution_check.sql
select
  ts,
  tx_hash,
  direction,
  transfer_label,
  tx_label_actions,
  tx_label_counterparty,
  tx_label_value,
  tx_label_asset,
  tx_label_leg_applies,
  tx_label_leg_match_reason,
  tx_label_applicable_leg_count,
  from_label,
  to_label,
  from_types,
  to_types,
  amount_value,
  stolen_amount_value
from transactions
where format = 'qlue_utxo'
  and transfer_label is not null
order by ts nulls last, tx_hash, direction
limit 200;

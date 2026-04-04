select
  ts,
  tx_hash,
  transfer_label,
  tx_label_actions,
  tx_label_counterparty,
  asset,
  amount_value,
  stolen_amount_value,
  amount_usd_value,
  stolen_amount_usd_value
from transactions
where (amount_value is not null and stolen_amount_value is not null and stolen_amount_value > amount_value)
   or (amount_usd_value is not null and stolen_amount_usd_value is not null and stolen_amount_usd_value > amount_usd_value)
order by ts desc, tx_hash
limit 100;

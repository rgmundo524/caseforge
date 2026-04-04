select
  ts,
  tx_hash,
  transfer_label,
  tx_label_actions,
  tx_label_counterparty,
  tx_label_value,
  tx_label_asset,
  tx_label_status,
  asset,
  amount_value,
  stolen_amount_value,
  amount_usd_value,
  stolen_amount_usd_value
from transactions
where tx_label_value is not null
   or transfer_label like '%(%'
order by ts desc, tx_hash
limit 100;

select
  ts,
  tx_hash,
  direction,
  transfer_label,
  asset,
  amount_value,
  tx_label_value,
  tx_label_asset,
  stolen_amount_value,
  amount_usd_value,
  stolen_amount_usd_value,
  tx_label_status
from transactions
where transfer_label like '%(%'
order by ts desc, tx_hash, direction nulls first
limit 150;

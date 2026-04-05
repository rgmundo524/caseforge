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
  theft_id,
  tx_label_status
from transactions
where transfer_label is not null
  and transfer_label not like '%(%'
  and tx_label_value is null
order by ts desc, tx_hash, direction nulls first
limit 150;

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
  theft_id
from transactions
where amount_value is not null
  and stolen_amount_value is not null
  and stolen_amount_value <> amount_value
order by ts desc, tx_hash, direction nulls first
limit 150;

select
  ts,
  tx_hash,
  direction,
  transfer_label,
  asset,
  amount_value,
  stolen_amount_value,
  amount_usd_value,
  stolen_amount_usd_value,
  cc_match_eligible
from transactions
where (amount_value is not null and stolen_amount_value is not null and stolen_amount_value > amount_value)
   or (amount_usd_value is not null and stolen_amount_usd_value is not null and stolen_amount_usd_value > amount_usd_value)
order by ts desc, tx_hash, direction nulls first
limit 100;

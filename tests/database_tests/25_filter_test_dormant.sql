select
  ts,
  tx_hash,
  direction,
  from_label,
  from_dormant_value,
  from_dormant_asset,
  to_label,
  to_dormant_value,
  to_dormant_asset,
  asset,
  amount_value,
  transfer_label
from transactions
where from_dormant_value is not null
   or to_dormant_value is not null
order by ts desc, tx_hash, direction nulls first
limit 100;

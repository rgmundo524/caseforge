-- Purpose: show rows where address-label dormant values were parsed.

select
  ts,
  tx_hash,
  transfer_label,
  from_label,
  from_types,
  from_counterparty,
  from_dormant_value,
  from_dormant_asset,
  from_address,
  to_label,
  to_types,
  to_counterparty,
  to_dormant_value,
  to_dormant_asset,
  to_address,
  asset,
  amount_value,
  amount_usd_value,
  stolen_amount_value,
  stolen_amount_usd_value
from transactions
where from_dormant_value is not null
   or to_dormant_value is not null
order by ts desc, tx_hash
limit 100;

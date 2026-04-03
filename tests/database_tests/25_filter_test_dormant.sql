-- Purpose: show rows where address-label dormant values were parsed.

select
  ts,
  tx_hash,
  transfer_label,
  from_label,
  from_types,
  from_counterparty,
  from_dormant_value_native,
  from_dormant_value_asset,
  from_address,
  to_label,
  to_types,
  to_counterparty,
  to_dormant_value_native,
  to_dormant_value_asset,
  to_address,
  asset,
  amount_native,
  amount_usd,
  stolen_amount_native,
  stolen_amount_usd
from transactions
where from_dormant_value_native is not null
   or to_dormant_value_native is not null
order by ts desc, tx_hash
limit 100;

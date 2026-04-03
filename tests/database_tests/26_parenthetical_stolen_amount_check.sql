select
  ts,
  tx_hash,
  transfer_label,
  tx_actions,
  tx_counterparty,
  tx_traced_value_native,
  tx_traced_value_asset,
  asset,
  amount_native,
  stolen_amount_native,
  amount_usd,
  stolen_amount_usd
from transactions
where tx_traced_value_native is not null
   or transfer_label like '%(%'
order by ts desc, tx_hash
limit 100;

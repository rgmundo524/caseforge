select
  ts,
  tx_hash,
  transfer_label,
  tx_actions,
  tx_counterparty,
  asset,
  amount_native,
  stolen_amount_native,
  amount_usd,
  stolen_amount_usd
from transactions
where (amount_native is not null and stolen_amount_native is not null and stolen_amount_native > amount_native)
   or (amount_usd is not null and stolen_amount_usd is not null and stolen_amount_usd > amount_usd)
order by ts desc, tx_hash
limit 100;

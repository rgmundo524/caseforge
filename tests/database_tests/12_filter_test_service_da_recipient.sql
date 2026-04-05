select
  ts,
  tx_hash,
  direction,
  from_label,
  from_address,
  to_label,
  to_address,
  asset,
  amount_value,
  stolen_amount_value,
  amount_usd_value,
  stolen_amount_usd_value,
  transfer_label,
  tx_label_actions,
  tx_label_counterparty
from transactions
where regexp_matches(coalesce(to_types, ''), '(^|[/\\])DA($|[/\\])', 'i')
order by ts desc, tx_hash, direction nulls first
limit 100;

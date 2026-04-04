select
  ts,
  tx_hash,
  transfer_label,
  tx_label_actions,
  tx_label_counterparty,
  from_label,
  from_types,
  from_counterparty,
  from_address,
  to_label,
  to_types,
  to_counterparty,
  to_address,
  asset,
  amount_value,
  stolen_amount_value,
  amount_usd_value,
  stolen_amount_usd_value,
  theft_id
from transactions
where regexp_matches(upper(coalesce(to_types, '')), '(^|[/\,;: ])DA($|[/\,;: ])')
order by ts desc, tx_hash
limit 100;

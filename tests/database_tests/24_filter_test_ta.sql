select
  ts,
  tx_hash,
  transfer_label,
  tx_actions,
  from_label,
  from_types,
  from_counterparty,
  from_address,
  to_label,
  to_types,
  to_counterparty,
  to_address,
  asset,
  amount_native,
  stolen_amount_native,
  amount_usd,
  stolen_amount_usd,
  theft_id
from transactions
where regexp_matches(upper(coalesce(from_types, '')), '(^|[/\\,;: ])TA($|[/\\,;: ])')
   or regexp_matches(upper(coalesce(to_types, '')), '(^|[/\\,;: ])TA($|[/\\,;: ])')
order by ts desc, tx_hash
limit 100;

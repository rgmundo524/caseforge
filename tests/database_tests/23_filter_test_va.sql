-- Purpose: show victim-typed rows. This includes both VA and VE labels.

select
  ts,
  tx_hash,
  transfer_label,
  tx_label_actions,
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
where regexp_matches(upper(coalesce(from_types, '')), '(^|[/\,;: ])VA($|[/\,;: ])')
   or regexp_matches(upper(coalesce(to_types, '')), '(^|[/\,;: ])VA($|[/\,;: ])')
   or regexp_matches(upper(coalesce(from_types, '')), '(^|[/\,;: ])VE($|[/\,;: ])')
   or regexp_matches(upper(coalesce(to_types, '')), '(^|[/\,;: ])VE($|[/\,;: ])')
order by ts desc, tx_hash
limit 100;

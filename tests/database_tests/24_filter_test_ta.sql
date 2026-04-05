select
  ts,
  tx_hash,
  direction,
  from_label,
  from_types,
  to_label,
  to_types,
  asset,
  amount_value,
  transfer_label
from transactions
where regexp_matches(coalesce(from_types, ''), '(^|[/\\])TA($|[/\\])', 'i')
   or regexp_matches(coalesce(to_types, ''), '(^|[/\\])TA($|[/\\])', 'i')
order by ts desc, tx_hash, direction nulls first
limit 100;

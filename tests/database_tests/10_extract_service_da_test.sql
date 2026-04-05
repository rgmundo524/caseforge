select
  tx_hash,
  transfer_label,
  to_types as recipient_types,
  to_counterparty as recipient_service,
  to_label as recipient_label
from transactions
where regexp_matches(coalesce(to_types, ''), '(^|[/\\])DA($|[/\\])', 'i')
order by recipient_service, tx_hash
limit 100;

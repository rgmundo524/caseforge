-- Purpose: extract service name from recipient labels whose parsed type block includes DA.

select
  tx_hash,
  transfer_label,
  to_types as recipient_types,
  to_counterparty as recipient_service,
  to_label as recipient_label
from transactions
where regexp_matches(upper(coalesce(to_types, '')), '(^|[/\,;: ])DA($|[/\,;: ])')
order by recipient_service, tx_hash
limit 100;

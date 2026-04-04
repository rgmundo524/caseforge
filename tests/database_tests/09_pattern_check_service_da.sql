-- Purpose: show recipient labels whose parsed type block includes DA.

select
  to_types as recipient_types,
  to_counterparty as recipient_service,
  to_label as recipient_label,
  count(*) as n
from transactions
where regexp_matches(upper(coalesce(to_types, '')), '(^|[/\,;: ])DA($|[/\,;: ])')
group by 1,2,3
order by n desc, recipient_service, recipient_label;

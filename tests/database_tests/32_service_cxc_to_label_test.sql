select
  to_types,
  to_counterparty,
  to_label,
  count(*) as n
from transactions
where regexp_matches(upper(coalesce(to_types, '')), '(^|[/\,;: ])CC($|[/\,;: ])')
group by 1,2,3
order by n desc, to_types, to_label;

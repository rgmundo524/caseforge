select
  from_types,
  from_counterparty,
  from_label,
  count(*) as n
from transactions
where regexp_matches(upper(coalesce(from_types, '')), '(^|[/\\,;: ])CC($|[/\\,;: ])')
group by 1,2,3
order by n desc, from_types, from_label;

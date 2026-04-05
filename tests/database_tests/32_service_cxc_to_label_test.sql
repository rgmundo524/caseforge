select
  to_label,
  count(*) as n
from transactions
where regexp_matches(coalesce(to_types, ''), '(^|[/\\])CC($|[/\\])', 'i')
group by 1
order by n desc, to_label;

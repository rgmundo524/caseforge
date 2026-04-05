select
  from_label,
  count(*) as n
from transactions
where regexp_matches(coalesce(from_types, ''), '(^|[/\\])CC($|[/\\])', 'i')
group by 1
order by n desc, from_label;

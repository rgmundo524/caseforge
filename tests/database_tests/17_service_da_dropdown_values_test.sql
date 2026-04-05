with values_cte as (
  select distinct lower(to_counterparty) as value, min(to_counterparty) as label
  from transactions
  where regexp_matches(coalesce(to_types, ''), '(^|[/\\])DA($|[/\\])', 'i')
    and trim(coalesce(to_counterparty, '')) <> ''
  group by lower(to_counterparty)
)
select 'all' as value, 'All' as label
union all
select value, label
from values_cte
order by label;

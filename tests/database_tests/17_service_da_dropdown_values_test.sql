-- Purpose: generate dropdown values for DA filtering.

with values_cte as (
  select distinct
    lower(trim(to_counterparty)) as value,
    to_counterparty as label
  from transactions
  where regexp_matches(upper(coalesce(to_types, '')), '(^|[/\,;: ])DA($|[/\,;: ])')
    and to_counterparty is not null
    and trim(to_counterparty) <> ''
)
select 'all' as value, 'All' as label
union all
select value, label
from values_cte
order by label;

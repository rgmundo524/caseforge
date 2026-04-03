-- Purpose: generate dropdown values for DA recipient filtering

with values_cte as (
  select distinct
    trim(to_counterparty) as service
  from transactions
  where regexp_matches(upper(coalesce(to_types, '')), '(^|[/\\,;: ])DA($|[/\\,;: ])')
)
select 'all' as value, 'All' as label
union all
select
  lower(service) as value,
  service as label
from values_cte
where service is not null
  and trim(service) <> ''
order by label;

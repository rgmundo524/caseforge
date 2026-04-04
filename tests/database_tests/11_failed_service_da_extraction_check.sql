-- Purpose: verify service extraction from DA-typed recipient labels is not blank.

with matches as (
  select
    to_label,
    to_counterparty as service
  from transactions
  where regexp_matches(upper(coalesce(to_types, '')), '(^|[/\,;: ])DA($|[/\,;: ])')
)
select
  count(*) as matching_rows,
  count(*) filter (where service is null) as null_extracts,
  count(*) filter (where trim(service) = '') as blank_extracts
from matches;

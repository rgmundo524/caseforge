-- Purpose: verify DA extraction is not blank

with matches as (
  select
    to_counterparty as recipient_service
  from transactions
  where regexp_matches(upper(coalesce(to_types, '')), '(^|[/\\,;: ])DA($|[/\\,;: ])')
)
select
  count(*) as matching_rows,
  count(*) filter (where recipient_service is null) as null_extracts,
  count(*) filter (where trim(recipient_service) = '') as blank_extracts
from matches;

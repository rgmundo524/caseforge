with matches as (
  select
    to_types,
    to_counterparty,
    to_label
  from transactions
  where regexp_matches(coalesce(to_types, ''), '(^|[/\\])DA($|[/\\])', 'i')
)
select
  count(*) as matching_rows,
  count(*) filter (where to_counterparty is null) as null_extracts,
  count(*) filter (where trim(coalesce(to_counterparty, '')) = '') as blank_extracts
from matches;

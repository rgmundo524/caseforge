-- Purpose: compare raw DA-like label count against parsed DA-type count.

select
  count(*) filter (
    where regexp_matches(upper(coalesce(to_label, '')), '^\s*[\[\{][^\]\}]*DA[^\]\}]*[\]\}]')
  ) as raw_matching_rows,
  count(*) filter (
    where regexp_matches(upper(coalesce(to_types, '')), '(^|[/\,;: ])DA($|[/\,;: ])')
  ) as parsed_matching_rows
from transactions;

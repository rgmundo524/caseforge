-- Purpose: compare raw bracket-match counts against parsed DA counts

with raw_match as (
  select count(*) as n
  from transactions
  where regexp_matches(
    upper(coalesce(to_label, '')),
    '^\[[^\]]*DA([/\\,;: ][^\]]*)?\]'
  )
),
parsed_match as (
  select count(*) as n
  from transactions
  where regexp_matches(upper(coalesce(to_types, '')), '(^|[/\\,;: ])DA($|[/\\,;: ])')
)
select
  (select n from raw_match) as raw_matching_rows,
  (select n from parsed_match) as parsed_matching_rows;

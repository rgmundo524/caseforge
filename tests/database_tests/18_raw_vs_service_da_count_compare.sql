with parsed_da as (
  select *
  from transactions
  where regexp_matches(coalesce(to_types, ''), '(^|[/\\])DA($|[/\\])', 'i')
), raw_da as (
  select *
  from transactions
  where regexp_matches(coalesce(to_label, ''), '^\[[^]]*DA[^]]*\]')
)
select
  (select count(*) from raw_da) as raw_matching_rows,
  (select count(*) from parsed_da) as parsed_matching_rows;

-- File: 20_theft_id_summary.sql
select
  count(*) as total_rows,
  count(*) filter (where regexp_matches(upper(coalesce(tx_actions, '')), '(^|[/\\,;: ])THEFT($|[/\\,;: ])')) as rows_with_theft_action,
  count(*) filter (where theft_id is not null) as rows_with_theft_id,
  count(distinct theft_id) filter (where theft_id is not null) as distinct_theft_ids,
  min(theft_id) as min_theft_id,
  max(theft_id) as max_theft_id
from transactions;

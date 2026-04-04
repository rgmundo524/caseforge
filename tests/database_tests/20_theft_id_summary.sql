-- File: 20_theft_id_summary.sql
select
  count(*) as total_rows,
  count(distinct tx_hash) as total_distinct_tx_hashes,
  count(*) filter (where tx_is_theft) as theft_rows,
  count(distinct tx_hash) filter (where tx_is_theft) as theft_distinct_tx_hashes,
  count(*) filter (where theft_id is not null) as rows_with_theft_id,
  count(distinct theft_id) filter (where theft_id is not null) as distinct_theft_ids,
  min(theft_id) as min_theft_id,
  max(theft_id) as max_theft_id
from transactions;

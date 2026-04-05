select
  count(*) as total_transfer_rows,
  count(*) filter (where theft_id is not null) as theft_transfer_rows,
  count(distinct tx_hash) filter (where theft_id is not null) as theft_transaction_hashes,
  count(distinct theft_id) as distinct_theft_ids,
  min(theft_id) as min_theft_id,
  max(theft_id) as max_theft_id
from transactions;

select
  theft_id,
  tx_hash,
  count(*) as transfer_rows_for_tx,
  min(ts) as first_ts,
  max(ts) as last_ts,
  min(transfer_label) as example_transfer_label
from transactions
where theft_id is not null
group by theft_id, tx_hash
order by theft_id, first_ts, tx_hash;

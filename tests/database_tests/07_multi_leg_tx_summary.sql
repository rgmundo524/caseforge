-- File: 07_multi_leg_tx_summary.sql
select
  tx_hash,
  count(*) as transfer_leg_count,
  count(*) filter (where direction = 'in') as input_leg_count,
  count(*) filter (where direction = 'out') as output_leg_count,
  min(chain) as chain,
  min(format) as format,
  min(ts) as first_seen_ts,
  max(ts) as last_seen_ts
from transactions
group by tx_hash
having count(*) > 1
order by transfer_leg_count desc, tx_hash
limit 200;

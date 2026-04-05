-- File: 07_multi_leg_tx_summary.sql
select
  tx_hash,
  count(*) as transfer_leg_count,
  count(*) filter (where lower(coalesce(direction, '')) = 'in') as input_leg_count,
  count(*) filter (where lower(coalesce(direction, '')) = 'out') as output_leg_count,
  min(ts) as first_seen_ts,
  max(ts) as last_seen_ts
from transactions
group by 1
having count(*) > 1
order by transfer_leg_count desc, tx_hash;

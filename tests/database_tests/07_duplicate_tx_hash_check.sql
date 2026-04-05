select
  tx_hash,
  count(*) as transfer_rows,
  min(chain) as chain,
  min(format) as format,
  string_agg(distinct coalesce(direction, 'null'), ' | ') as directions,
  sum(coalesce(amount_value, 0)) as total_amount_value,
  min(ts) as first_ts,
  max(ts) as last_ts
from transactions
group by tx_hash
having count(*) > 1
order by transfer_rows desc, tx_hash;

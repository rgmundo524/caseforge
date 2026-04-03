-- File: 13_group_by_asset.sql
select
  asset,
  sum(amount_native) as total_amount_native,
  sum(stolen_amount_native) as total_traced_native,
  sum(amount_usd) as total_amount_usd,
  sum(stolen_amount_usd) as total_traced_usd,
  count(*) as tx_count
from transactions
group by 1
order by total_traced_usd desc nulls last, total_amount_usd desc nulls last;

-- File: 13_group_by_asset.sql
select
  asset,
  sum(amount_value) as total_amount_value,
  sum(stolen_amount_value) as total_stolen_amount_value,
  sum(amount_usd_value) as total_amount_usd_value,
  sum(stolen_amount_usd_value) as total_stolen_amount_usd_value,
  count(*) as tx_count
from transactions
group by 1
order by total_amount_usd_value desc nulls last, total_amount_value desc nulls last;

-- Rollup of deposit exposure by service and asset.
with deposits as (
  select
    chain,
    coalesce(nullif(trim(to_counterparty), ''), nullif(trim(tx_label_counterparty), ''), 'Unknown') as recipient_service,
    asset,
    amount_value,
    amount_usd_value,
    stolen_amount_value,
    stolen_amount_usd_value,
    tx_hash,
    transfer_row_id
  from transactions
  where regexp_matches('/' || coalesce(to_types, '') || '/', '(^|/)(DA)(/|$)')
)
select
  chain,
  recipient_service,
  asset,
  count(*) as transfer_rows,
  count(distinct tx_hash) as distinct_transactions,
  sum(amount_value) as gross_amount_value,
  sum(amount_usd_value) as gross_amount_usd_value,
  sum(stolen_amount_value) as stolen_amount_value,
  sum(stolen_amount_usd_value) as stolen_amount_usd_value
from deposits
group by 1,2,3
order by stolen_amount_usd_value desc nulls last,
         stolen_amount_value desc nulls last,
         transfer_rows desc;

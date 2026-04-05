with service_da as (
  select
    ts,
    tx_hash,
    direction,
    to_counterparty as service,
    from_label,
    from_address,
    to_label,
    to_address,
    asset,
    amount_value,
    stolen_amount_value,
    amount_usd_value,
    stolen_amount_usd_value,
    transfer_label,
    theft_id
  from transactions
  where regexp_matches(coalesce(to_types, ''), '(^|[/\\])DA($|[/\\])', 'i')
)
select *
from service_da
order by ts desc, tx_hash, direction nulls first
limit 100;

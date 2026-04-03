with service_da as (
  select
    ts,
    tx_hash,
    transfer_label,
    tx_actions,
    tx_counterparty,
    to_types as recipient_types,
    to_counterparty as recipient_service,
    from_label,
    from_address,
    to_label as recipient_label,
    to_address,
    asset,
    amount_native,
    stolen_amount_native,
    amount_usd,
    stolen_amount_usd,
    theft_id
  from transactions
  where regexp_matches(upper(coalesce(to_types, '')), '(^|[/\\,;: ])DA($|[/\\,;: ])')
)
select *
from service_da
order by ts desc nulls last, tx_hash
limit 100;

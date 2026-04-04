with service_da as (
  select
    ts,
    tx_hash,
    to_counterparty as service,
    transfer_label,
    tx_label_actions,
    tx_label_counterparty,
    from_label,
    from_address,
    to_label,
    to_address,
    asset,
    amount_value,
    stolen_amount_value,
    amount_usd_value,
    stolen_amount_usd_value,
    theft_id,
    tx_is_theft,
    tx_is_cross_chain,
    tx_cc_id,
    tx_cc_direction
  from transactions
  where regexp_matches(upper(coalesce(to_types, '')), '(^|[/\,;: ])DA($|[/\,;: ])')
)
select *
from service_da
order by ts desc, tx_hash
limit 100;

with service_da as (
  select
    ts as time,
    tx_hash as transaction,
    transfer_label,
    tx_actions,
    tx_counterparty,
    from_types as source_types,
    from_counterparty as source_counterparty,
    from_label as source_address_label,
    from_address as source_address_hash,
    to_types as recipient_types,
    to_counterparty as recipient_service,
    to_label as recipient_address_label,
    to_address as recipient_address_hash,
    amount_native as crypto_value,
    asset as crypto_asset,
    amount_usd as usd,
    stolen_amount_native,
    stolen_amount_usd,
    theft_id
  from transactions
  where regexp_matches(upper(coalesce(to_types, '')), '(^|[/\\,;: ])DA($|[/\\,;: ])')
)
select *
from service_da
order by time desc nulls last, transaction
limit 100;

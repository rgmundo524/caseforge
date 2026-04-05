with service_da as (
  select
    ts as time,
    tx_hash as transaction,
    direction,
    to_counterparty as service,
    from_label as source_address_label,
    from_address as source_address_hash,
    to_label as recipient_address_label,
    to_address as recipient_address_hash,
    amount_value as crypto_value,
    asset as crypto_asset,
    amount_usd_value as usd,
    stolen_amount_value,
    stolen_amount_usd_value,
    transfer_label,
    theft_id
  from transactions
  where regexp_matches(coalesce(to_types, ''), '(^|[/\\])DA($|[/\\])', 'i')
)
select *
from service_da
order by time desc, transaction, direction nulls first
limit 100;

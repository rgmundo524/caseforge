with service_da as (
  select
    ts as time,
    tx_hash as transaction,
    transfer_label,
    tx_label_actions as transaction_actions,
    tx_label_counterparty as transaction_counterparty,
    from_label as source_address_label,
    from_address as source_address_hash,
    to_label as recipient_address_label,
    to_address as recipient_address_hash,
    to_counterparty as recipient_service,
    amount_value as crypto_value,
    asset as crypto_asset,
    amount_usd_value as usd,
    stolen_amount_value as stolen_value,
    stolen_amount_usd_value as stolen_usd,
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
order by time desc, transaction
limit 100;

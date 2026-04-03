-- File: 12_filter_test_service_da_recipient.sql
select
  ts,
  tx_hash,
  transfer_label,
  tx_actions,
  from_types,
  from_counterparty,
  from_label,
  from_address,
  to_types as recipient_types,
  to_counterparty as recipient_service,
  to_label as recipient_label,
  to_address,
  asset,
  amount_native,
  stolen_amount_native,
  amount_usd,
  stolen_amount_usd
from transactions
where regexp_matches(upper(coalesce(to_types, '')), '(^|[/\\,;: ])DA($|[/\\,;: ])')
order by ts desc nulls last, tx_hash
limit 100;

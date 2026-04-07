-- Transfer legs identified as deposits to recipient services.
select
  transfer_row_id,
  tx_hash,
  ts,
  chain,
  format,
  direction,
  transfer_label,
  tx_label_entry_raw,
  tx_label_actions,
  tx_label_counterparty,
  tx_label_leg_applies,
  tx_label_leg_match_reason,
  from_address,
  from_label,
  from_types,
  from_counterparty,
  to_address,
  to_label,
  to_types,
  coalesce(nullif(trim(to_counterparty), ''), nullif(trim(tx_label_counterparty), '')) as recipient_service,
  asset,
  amount_value,
  amount_usd_value,
  stolen_amount_value,
  stolen_amount_usd_value,
  source_file
from transactions
where regexp_matches('/' || coalesce(to_types, '') || '/', '(^|/)(DA)(/|$)')
order by ts nulls last, tx_hash, transfer_row_id;

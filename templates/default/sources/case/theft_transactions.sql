-- Theft-related transfer legs for the default theft-tracing template.
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
  tx_is_theft,
  theft_id,
  from_address,
  from_label,
  from_types,
  from_counterparty,
  to_address,
  to_label,
  to_types,
  to_counterparty,
  asset,
  amount_value,
  amount_usd_value,
  stolen_amount_value,
  stolen_amount_usd_value,
  source_file
from transactions
where tx_is_theft
   or regexp_matches('/' || coalesce(from_types, '') || '/', '(^|/)(TA)(/|$)')
   or regexp_matches('/' || coalesce(to_types, '') || '/', '(^|/)(TA)(/|$)')
order by theft_id nulls last, ts nulls last, tx_hash, transfer_row_id;

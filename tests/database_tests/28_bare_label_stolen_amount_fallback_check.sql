-- File: 28_bare_label_stolen_amount_fallback_check.sql
select
  tx_hash,
  direction,
  transfer_label,
  tx_label_entry_raw,
  tx_label_scope,
  tx_label_value,
  tx_label_asset,
  tx_label_status,
  tx_label_assignment_status,
  asset,
  amount_value,
  stolen_amount_value
from transactions
where
  regexp_matches(coalesce(transfer_label, ''), '^\s*[-+]?(?:[0-9][0-9,]*(?:\.[0-9]+)?|\.[0-9]+)\s*$')
  or regexp_matches(coalesce(tx_label_entry_raw, ''), '^\s*[-+]?(?:[0-9][0-9,]*(?:\.[0-9]+)?|\.[0-9]+)\s*$')
order by ts nulls last, tx_hash, transfer_row_id
limit 200;

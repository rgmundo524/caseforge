-- File: 28_bare_label_stolen_amount_fallback_check.sql
select
  ts,
  tx_hash,
  direction,
  transfer_label,
  tx_label_value,
  tx_label_asset,
  tx_label_status,
  tx_label_leg_applies,
  tx_label_leg_match_reason,
  asset,
  amount_value,
  amount_usd_value,
  stolen_amount_value,
  stolen_amount_usd_value,
  theft_id
from transactions
where transfer_label is not null
  and regexp_matches(trim(coalesce(transfer_label, '')), '^[-+]?(?:[0-9][0-9,]*(\.[0-9]+)?|\.[0-9]+)$')
order by ts desc, tx_hash, direction
limit 100;

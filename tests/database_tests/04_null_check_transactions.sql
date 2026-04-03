-- File: 04_null_check_transactions.sql
select
  count(*) as total_rows,
  count(*) filter (where ts is null) as null_ts,
  count(*) filter (where tx_hash is null) as null_tx_hash,
  count(*) filter (where from_address is null) as null_from_address,
  count(*) filter (where to_address is null) as null_to_address,
  count(*) filter (where asset is null) as null_asset,
  count(*) filter (where amount_native is null) as null_amount_native,
  count(*) filter (where transfer_label is null) as null_transfer_label,
  count(*) filter (where from_label is null) as null_from_label,
  count(*) filter (where to_label is null) as null_to_label
from transactions;

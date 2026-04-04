-- File: 04_null_check_transactions.sql
select
  count(*) as total_rows,
  count(*) filter (where ts is null) as null_ts,
  count(*) filter (where tx_hash is null) as null_tx_hash,
  count(*) filter (where from_address is null) as null_from_address,
  count(*) filter (where to_address is null) as null_to_address,
  count(*) filter (where asset is null) as null_asset,
  count(*) filter (where amount_value is null) as null_amount_value,
  count(*) filter (where amount_usd_value is null) as null_amount_usd_value,
  count(*) filter (where stolen_amount_value is null) as null_stolen_amount_value,
  count(*) filter (where stolen_amount_usd_value is null) as null_stolen_amount_usd_value
from transactions;

select
  count(*) as total_rows,
  count(*) filter (where ts is null) as null_ts,
  count(*) filter (where tx_hash is null) as null_tx_hash,
  count(*) filter (where asset is null) as null_asset,
  count(*) filter (where amount_value is null) as null_amount_value,
  count(*) filter (where amount_usd_value is null) as null_amount_usd_value,
  count(*) filter (where format = 'qlue_account' and from_address is null) as account_rows_null_from_address,
  count(*) filter (where format = 'qlue_account' and to_address is null) as account_rows_null_to_address,
  count(*) filter (where format = 'qlue_utxo' and direction = 'in' and from_address is null) as utxo_in_rows_null_from_address,
  count(*) filter (where format = 'qlue_utxo' and direction = 'out' and to_address is null) as utxo_out_rows_null_to_address
from transactions;

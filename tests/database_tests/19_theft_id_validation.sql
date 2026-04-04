-- File: 19_theft_id_validation.sql
select
  theft_id,
  ts,
  tx_hash,
  transfer_label,
  tx_label_actions,
  tx_label_counterparty,
  tx_label_value,
  tx_label_asset,
  tx_is_theft,
  count(*) over (partition by tx_hash) as rows_for_tx_hash
from transactions
where tx_is_theft
   or theft_id is not null
order by theft_id, ts, tx_hash;

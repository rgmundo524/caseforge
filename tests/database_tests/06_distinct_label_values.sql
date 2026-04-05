select distinct
  transfer_label,
  tx_label_actions,
  tx_label_counterparty,
  tx_label_value,
  tx_label_asset,
  tx_label_status
from transactions
where transfer_label is not null
order by transfer_label
limit 200;

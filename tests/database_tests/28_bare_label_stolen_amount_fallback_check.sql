select
  ts,
  tx_hash,
  transfer_label,
  tx_label_actions,
  tx_label_counterparty,
  tx_label_value,
  asset,
  amount_value,
  stolen_amount_value,
  case
    when amount_value is not null
     and stolen_amount_value is not null
     and amount_value = stolen_amount_value
    then 'fallback_to_amount_value'
    else 'non_equal_or_null'
  end as fallback_status,
  amount_usd_value,
  stolen_amount_usd_value,
  theft_id
from transactions
where tx_label_value is null
  and transfer_label is not null
  and transfer_label not like '%(%'
order by ts desc, tx_hash
limit 100;

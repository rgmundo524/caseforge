select
  ts,
  tx_hash,
  transfer_label,
  tx_actions,
  tx_counterparty,
  tx_traced_value_native,
  asset,
  amount_native,
  stolen_amount_native,
  case
    when amount_native is not null
     and stolen_amount_native is not null
     and amount_native = stolen_amount_native
    then 'fallback_to_amount_native'
    else 'non_equal_or_null'
  end as fallback_status,
  amount_usd,
  stolen_amount_usd,
  theft_id
from transactions
where transfer_label is not null
  and transfer_label not like '%(%'
  and regexp_matches(
        trim(coalesce(transfer_label, '')),
        '^[-+]?(?:[0-9][0-9,]*(\.[0-9]+)?|\.[0-9]+)(?:\s+[A-Za-z0-9._-]+)?(?:\s|$)'
      )
order by ts desc, tx_hash
limit 100;

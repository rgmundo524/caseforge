select
  ts,
  tx_hash,
  transfer_label,
  tx_label_actions,
  tx_label_counterparty,
  tx_is_cross_chain,
  tx_cc_id,
  tx_cc_direction,
  from_label,
  from_types,
  from_counterparty,
  from_address,
  to_label,
  to_types,
  to_counterparty,
  to_address,
  asset,
  amount_value,
  stolen_amount_value,
  amount_usd_value,
  stolen_amount_usd_value,
  theft_id
from transactions
where tx_is_cross_chain
   or regexp_matches(upper(coalesce(from_types, '')), '(^|[/\,;: ])CC($|[/\,;: ])')
   or regexp_matches(upper(coalesce(to_types, '')), '(^|[/\,;: ])CC($|[/\,;: ])')
order by ts desc, tx_hash
limit 100;

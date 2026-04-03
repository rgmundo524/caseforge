-- File: 19_theft_id_validation.sql
select
  theft_id,
  ts,
  tx_hash,
  transfer_label,
  tx_actions,
  tx_counterparty,
  stolen_amount_native,
  stolen_amount_usd
from transactions
where theft_id is not null
   or regexp_matches(upper(coalesce(tx_actions, '')), '(^|[/\\,;: ])THEFT($|[/\\,;: ])')
order by theft_id, ts, tx_hash;

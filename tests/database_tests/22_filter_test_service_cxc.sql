select
  ts,
  tx_hash,
  chain,
  format,
  direction,
  cc_match_side,
  cc_match_eligible,
  from_label,
  to_label,
  asset,
  amount_value,
  amount_usd_value,
  transfer_label,
  tx_label_actions,
  tx_label_counterparty,
  tx_cc_id,
  tx_cc_direction
from transactions
where tx_is_cross_chain
order by tx_cc_id, tx_hash, direction nulls first, ts
limit 200;

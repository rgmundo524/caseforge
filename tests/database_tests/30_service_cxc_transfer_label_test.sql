select
  tx_cc_id,
  tx_cc_direction,
  tx_hash,
  count(*) as transfer_rows,
  sum(case when cc_match_eligible then 1 else 0 end) as eligible_rows,
  min(transfer_label) as example_transfer_label
from transactions
where tx_is_cross_chain
group by 1,2,3
order by tx_cc_id, tx_cc_direction, tx_hash;

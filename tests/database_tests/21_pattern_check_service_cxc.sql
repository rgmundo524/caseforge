select
  tx_label_actions,
  tx_label_counterparty,
  tx_cc_id,
  tx_cc_direction,
  count(*) as transfer_rows
from transactions
where tx_is_cross_chain
group by 1,2,3,4
order by tx_cc_id, tx_cc_direction, tx_label_counterparty;

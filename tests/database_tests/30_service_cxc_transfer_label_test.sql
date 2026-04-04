select
  tx_label_actions,
  tx_cc_id,
  tx_cc_direction,
  tx_label_counterparty,
  transfer_label,
  count(*) as n
from transactions
where tx_is_cross_chain
group by 1,2,3,4,5
order by n desc, tx_label_actions, transfer_label;

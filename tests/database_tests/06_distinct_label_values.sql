-- File: 06_distinct_label_values.sql
select distinct
  transfer_label,
  tx_actions,
  tx_counterparty,
  from_label,
  from_types,
  from_counterparty,
  to_label,
  to_types,
  to_counterparty
from transactions
where transfer_label is not null
   or from_label is not null
   or to_label is not null
order by transfer_label, from_label, to_label
limit 200;

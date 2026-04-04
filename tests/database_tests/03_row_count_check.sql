-- File: 03_row_count_check.sql
select
  count(*) as total_rows,
  count(distinct tx_hash) as distinct_tx_hashes,
  count(*) filter (where tx_label_actions is not null) as rows_with_tx_label_actions,
  count(*) filter (where tx_label_counterparty is not null) as rows_with_tx_label_counterparty,
  count(*) filter (where tx_label_value is not null) as rows_with_tx_label_value,
  count(*) filter (where from_types is not null) as rows_with_from_types,
  count(*) filter (where to_types is not null) as rows_with_to_types,
  count(*) filter (where theft_id is not null) as rows_with_theft_id,
  count(*) filter (where tx_is_theft) as rows_marked_theft,
  count(*) filter (where tx_is_cross_chain) as rows_marked_cross_chain,
  count(*) filter (where tx_label_status <> 'ok' or from_label_status <> 'ok' or to_label_status <> 'ok' or time_status <> 'ok' or amount_status <> 'ok' or usd_status <> 'ok') as rows_with_non_ok_status
from transactions;

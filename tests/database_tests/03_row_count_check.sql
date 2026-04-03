-- File: 03_row_count_check.sql
select
  count(*) as row_count,
  count(*) filter (where tx_actions is not null) as rows_with_tx_actions,
  count(*) filter (where from_types is not null) as rows_with_from_types,
  count(*) filter (where to_types is not null) as rows_with_to_types,
  count(*) filter (where tx_traced_value_native is not null) as rows_with_tx_traced_value,
  count(*) filter (where from_dormant_value_native is not null) as rows_with_from_dormant_value,
  count(*) filter (where to_dormant_value_native is not null) as rows_with_to_dormant_value
from transactions;

select
  count(*) as transfer_rows,
  count(distinct tx_hash) as distinct_tx_hashes,
  count(*) filter (where tx_label_actions is not null) as rows_with_tx_label_actions,
  count(*) filter (where transfer_label is not null) as rows_with_transfer_label,
  count(distinct tx_hash) filter (where tx_is_theft) as distinct_theft_tx_hashes,
  count(distinct tx_hash) filter (where tx_is_cross_chain) as distinct_cross_chain_tx_hashes,
  count(*) filter (where tx_hash in (
    select tx_hash from transactions group by tx_hash having count(*) > 1
  )) as rows_in_multi_transfer_transactions,
  count(distinct tx_hash) filter (where tx_hash in (
    select tx_hash from transactions group by tx_hash having count(*) > 1
  )) as multi_transfer_transaction_hashes
from transactions;

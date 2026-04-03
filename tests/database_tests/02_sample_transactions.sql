-- File: 02_sample_transactions.sql
-- Purpose: sample parsed transaction rows with additional raw-normalized context.

with raw_one as (
  select
    *,
    row_number() over (
      partition by source_file, tx
      order by time nulls last, source_address, destination_address
    ) as rn
  from v_normalized_transactions
)
select
  t.vendor,
  t.format,
  t.chain,
  t.ts,
  t.tx_hash,
  t.transfer_label,
  t.tx_label_has_multiple_segments,
  t.tx_actions,
  t.tx_counterparty,
  t.tx_traced_value_native,
  t.tx_traced_value_asset,
  t.from_label,
  t.from_types,
  t.from_counterparty,
  t.from_dormant_value_native,
  t.from_dormant_value_asset,
  t.from_address,
  t.to_label,
  t.to_types,
  t.to_counterparty,
  t.to_dormant_value_native,
  t.to_dormant_value_asset,
  t.to_address,
  t.asset,
  t.amount_native,
  t.amount_usd,
  t.stolen_amount_native,
  t.stolen_amount_usd,
  t.theft_id,
  t.source_file,
  r.blockchain as raw_blockchain,
  r.tx_label as raw_tx_label,
  r.source_group,
  r.source_group_description,
  r.destination_group,
  r.destination_group_description
from transactions t
left join raw_one r
  on r.source_file = t.source_file
 and r.tx = t.tx_hash
 and r.rn = 1
order by t.ts desc nulls last, t.tx_hash
limit 25;

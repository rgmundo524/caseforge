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
  t.tx_label_actions,
  t.tx_label_counterparty,
  t.tx_label_value,
  t.tx_label_asset,
  t.tx_label_status,
  t.from_label,
  t.from_types,
  t.from_counterparty,
  t.from_dormant_value,
  t.from_dormant_asset,
  t.from_label_status,
  t.from_address,
  t.to_label,
  t.to_types,
  t.to_counterparty,
  t.to_dormant_value,
  t.to_dormant_asset,
  t.to_label_status,
  t.to_address,
  t.asset,
  t.amount_value,
  t.amount_usd_value,
  t.stolen_amount_value,
  t.stolen_amount_usd_value,
  t.theft_id,
  t.tx_is_theft,
  t.tx_is_cross_chain,
  t.tx_cc_id,
  t.tx_cc_direction,
  t.time_status,
  t.amount_status,
  t.usd_status,
  t.source_file,
  r.blockchain as raw_blockchain,
  r.tx_label as raw_tx_label,
  r.source_group,
  r.source_group_description,
  r.destination_group,
  r.destination_group_description,
  r.value as raw_value,
  r.usd as raw_usd,
  r.time as raw_time
from transactions t
left join raw_one r
  on r.source_file = t.source_file
 and r.tx = t.tx_hash
 and r.rn = 1
order by t.ts desc nulls last, t.tx_hash
limit 25;

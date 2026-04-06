-- File: 36_multi_entry_tx_label_resolution.sql
select
  r.tx_hash,
  r.entry_index,
  r.entry_raw,
  r.entry_scope,
  r.entry_actions,
  r.entry_counterparty,
  r.entry_value,
  r.entry_asset,
  r.entry_status,
  r.entry_resolution_status,
  r.candidate_row_count,
  r.assigned_row_count,
  a.transfer_row_id,
  a.assignment_reason,
  a.allocated_stolen_amount_value
from v_tx_label_entry_resolution r
left join v_tx_label_entry_assignments a using (entry_id)
where r.label_owner_id like 'utxo:%'
order by r.tx_hash, r.entry_index, a.transfer_row_id
limit 400;

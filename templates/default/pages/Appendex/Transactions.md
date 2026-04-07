---
fullWidth: true
sidebar_position: 1
---

# Appendix

## Related Transfer Details
Each row below is a **transfer leg**. Multiple rows can share the same transaction hash when a single blockchain transaction contains multiple transfers or multiple UTXO inputs/outputs.

```sql chains
select 'all' as value, 'All' as label
union all
select distinct
  lower(chain) as value,
  upper(substr(chain, 1, 1)) || lower(substr(chain, 2)) as label
from "case".transactions
where chain is not null
order by label;
```

<Dropdown
  data={chains}
  name=chain_filter
  value=value
  label=label
  title="Chain"
  defaultValue="all"
/>

```sql transfers_by_chain
select
  upper(substr(coalesce(chain, ''), 1, 1)) || lower(substr(coalesce(chain, ''), 2)) as chain,
  transfer_row_id,
  tx_hash,
  direction,
  transfer_label,
  tx_label_entry_raw,
  tx_label_scope,
  tx_label_actions,
  tx_label_counterparty,
  tx_label_value,
  tx_label_asset,
  tx_label_status,
  tx_label_assignment_status,
  tx_label_entry_count,
  tx_label_assigned_entry_count,
  tx_label_leg_applies,
  tx_label_leg_match_reason,
  tx_label_applicable_leg_count,
  ts,
  from_label,
  to_label,
  asset,
  amount_value,
  stolen_amount_value,
  source_file
from "case".transactions
where
  '${inputs.chain_filter.value}' = 'all'
  or lower(chain) = '${inputs.chain_filter.value}'
order by ts nulls last, tx_hash, transfer_row_id;
```

<DataTable data={transfers_by_chain} title="Transfer Legs by Blockchain" subtitle="Filtered by Chain" search download rows=20 rowNumbers rowLines rowShading>
  <Column id=chain title="Blockchain" />
  <Column id=transfer_row_id title="Transfer Row ID" />
  <Column id=tx_hash title="Transaction Hash" />
  <Column id=direction title="Direction" />
  <Column id=transfer_label title="Raw Tx Label" />
  <Column id=tx_label_entry_raw title="Applied Label Entry" />
  <Column id=tx_label_scope title="Entry Scope" />
  <Column id=tx_label_actions title="Actions" />
  <Column id=tx_label_counterparty title="Tx Counterparty" />
  <Column id=tx_label_value title="Tx Label Value" />
  <Column id=tx_label_asset title="Tx Label Asset" />
  <Column id=tx_label_status title="Tx Label Status" />
  <Column id=tx_label_assignment_status title="Assignment Status" />
  <Column id=tx_label_entry_count title="Total Entries" />
  <Column id=tx_label_assigned_entry_count title="Assigned Entries on Row" />
  <Column id=tx_label_leg_applies title="Label Applies To This Row" />
  <Column id=tx_label_leg_match_reason title="Assignment Reason" />
  <Column id=tx_label_applicable_leg_count title="Applicable Legs / Tx" />
  <Column id=ts title="Date/Time" />
  <Column id=from_label title="Sender Label" />
  <Column id=to_label title="Recipient Label" />
  <Column id=asset title="Asset" />
  <Column id=amount_value title="Transfer Value" />
  <Column id=stolen_amount_value title="Stolen Value" />
  <Column id=source_file title="Source File" />
</DataTable>

## Transaction Label Entries
This table shows each **comma-separated transaction-label entry** after parsing. For UTXO transactions, a single raw transaction label can produce multiple entries.

```sql tx_label_entries
select
  tx_hash,
  entry_id,
  entry_index,
  entry_raw,
  entry_scope,
  entry_actions,
  entry_counterparty,
  entry_value,
  entry_asset,
  entry_status,
  entry_is_cross_chain,
  entry_cc_id,
  entry_cc_direction,
  entry_side_hint
from "case".v_tx_label_entries
order by tx_hash, entry_index, entry_id;
```

<DataTable data={tx_label_entries} title="Transaction Label Entries" search download rows=20 rowNumbers rowLines rowShading>
  <Column id=tx_hash title="Transaction Hash" />
  <Column id=entry_id title="Entry ID" />
  <Column id=entry_index title="Entry Index" />
  <Column id=entry_raw title="Raw Entry" />
  <Column id=entry_scope title="Scope" />
  <Column id=entry_actions title="Actions" />
  <Column id=entry_counterparty title="Counterparty" />
  <Column id=entry_value title="Entry Value" />
  <Column id=entry_asset title="Entry Asset" />
  <Column id=entry_status title="Parse Status" />
  <Column id=entry_is_cross_chain title="Cross-Chain" />
  <Column id=entry_cc_id title="CC Group" />
  <Column id=entry_cc_direction title="CC Direction" />
  <Column id=entry_side_hint title="Side Hint" />
</DataTable>

## Transaction Label Entry Resolution
This table shows whether each parsed label entry was resolved to one or more transfer rows.

```sql tx_label_entry_resolution
select
  tx_hash,
  entry_id,
  entry_index,
  entry_raw,
  entry_scope,
  entry_resolution_status,
  candidate_row_count,
  assigned_row_count,
  ambiguous_row_count
from "case".v_tx_label_entry_resolution
order by tx_hash, entry_index, entry_id;
```

<DataTable data={tx_label_entry_resolution} title="Transaction Label Entry Resolution" search download rows=20 rowNumbers rowLines rowShading>
  <Column id=tx_hash title="Transaction Hash" />
  <Column id=entry_id title="Entry ID" />
  <Column id=entry_index title="Entry Index" />
  <Column id=entry_raw title="Raw Entry" />
  <Column id=entry_scope title="Scope" />
  <Column id=entry_resolution_status title="Resolution Status" />
  <Column id=candidate_row_count title="Candidate Rows" />
  <Column id=assigned_row_count title="Assigned Rows" />
  <Column id=ambiguous_row_count title="Ambiguous Rows" />
</DataTable>

## Cross-Chain Transaction Legs

```sql cross_chain_tx_legs
select
  tx_cc_id,
  tx_cc_direction,
  tx_hash,
  chain,
  format,
  cc_match_side,
  eligible_transfer_rows,
  cc_match_amount_value,
  cc_match_amount_usd_value,
  asset_example,
  tx_label_counterparty,
  tx_label_value,
  tx_label_asset,
  tx_label_scope,
  ts
from "case".v_cross_chain_tx_legs
order by tx_cc_id, tx_cc_direction, ts;
```

<DataTable data={cross_chain_tx_legs} title="Cross-Chain Transaction Legs" search download rows=20 rowNumbers rowLines rowShading>
  <Column id=tx_cc_id title="CC Group" />
  <Column id=tx_cc_direction title="CC Direction" />
  <Column id=tx_hash title="Transaction Hash" />
  <Column id=chain title="Chain" />
  <Column id=format title="Format" />
  <Column id=cc_match_side title="Match Side" />
  <Column id=eligible_transfer_rows title="Eligible Rows" />
  <Column id=cc_match_amount_value title="Matched Value" />
  <Column id=cc_match_amount_usd_value title="Matched USD Value" fmt=usd />
  <Column id=asset_example title="Asset" />
  <Column id=tx_label_counterparty title="Counterparty" />
  <Column id=tx_label_value title="Label Value" />
  <Column id=tx_label_asset title="Label Asset" />
  <Column id=tx_label_scope title="Label Scope" />
  <Column id=ts title="Time" />
</DataTable>

## Cross-Chain Pairing

```sql cross_chain_pairs
select
  tx_cc_id,
  in_tx_hash,
  in_chain,
  in_effective_match_value,
  in_effective_match_asset,
  in_counterparty,
  in_ts,
  out_tx_hash,
  out_chain,
  out_effective_match_value,
  out_effective_match_asset,
  out_counterparty,
  out_ts,
  cc_pair_status,
  cc_timing_status,
  cc_timing_delta_hours
from "case".v_cross_chain_pairs
order by tx_cc_id;
```

<DataTable data={cross_chain_pairs} title="Cross-Chain Pairing" search download rows=20 rowNumbers rowLines rowShading>
  <Column id=tx_cc_id title="CC Group" />
  <Column id=in_tx_hash title="IN Tx Hash" />
  <Column id=in_chain title="IN Chain" />
  <Column id=in_effective_match_value title="IN Effective Value" />
  <Column id=in_effective_match_asset title="IN Effective Asset" />
  <Column id=in_counterparty title="IN Counterparty" />
  <Column id=in_ts title="IN Time" />
  <Column id=out_tx_hash title="OUT Tx Hash" />
  <Column id=out_chain title="OUT Chain" />
  <Column id=out_effective_match_value title="OUT Effective Value" />
  <Column id=out_effective_match_asset title="OUT Effective Asset" />
  <Column id=out_counterparty title="OUT Counterparty" />
  <Column id=out_ts title="OUT Time" />
  <Column id=cc_pair_status title="Pair Status" />
  <Column id=cc_timing_status title="Timing Status" />
  <Column id=cc_timing_delta_hours title="Timing Δ Hours" />
</DataTable>

## Rows Needing Review

```sql issue_rows
select
  transfer_row_id,
  tx_hash,
  direction,
  transfer_label,
  tx_label_entry_raw,
  tx_label_scope,
  tx_label_status,
  tx_label_assignment_status,
  tx_label_leg_match_reason,
  amount_value,
  stolen_amount_value,
  issue_flags
from "case".v_issue_rows
order by ts nulls last, tx_hash, transfer_row_id;
```

<DataTable data={issue_rows} title="Rows Needing Review" search download rows=20 rowNumbers rowLines rowShading>
  <Column id=transfer_row_id title="Transfer Row ID" />
  <Column id=tx_hash title="Transaction Hash" />
  <Column id=direction title="Direction" />
  <Column id=transfer_label title="Raw Tx Label" />
  <Column id=tx_label_entry_raw title="Applied Entry" />
  <Column id=tx_label_scope title="Entry Scope" />
  <Column id=tx_label_status title="Label Status" />
  <Column id=tx_label_assignment_status title="Assignment Status" />
  <Column id=tx_label_leg_match_reason title="Assignment Reason" />
  <Column id=amount_value title="Transfer Value" />
  <Column id=stolen_amount_value title="Stolen Value" />
  <Column id=issue_flags title="Issue Flags" />
</DataTable>

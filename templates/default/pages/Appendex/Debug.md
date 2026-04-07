---
fullWidth: true
sidebar_position: 99
---

# Debug & QA

This appendix page is intended for manual verification of the extracted Evidence source tables. It uses the `case.*` source-query tables rather than querying the live DuckDB file directly.

```sql chain_filter_values
select 'all' as value, 'All' as label
union all
select distinct lower(chain) as value,
       upper(substr(chain, 1, 1)) || lower(substr(chain, 2)) as label
from case.transactions
where chain is not null
order by label;
```

<Dropdown
  data={chain_filter_values}
  name=chain_filter
  value=value
  label=label
  title="Chain"
  defaultValue="all"
/>

```sql source_row_counts
select 'transactions' as dataset, count(*) as row_count from case.transactions
union all select 'issue_rows', count(*) from case.issue_rows
union all select 'cross_chain_pairs', count(*) from case.cross_chain_pairs
union all select 'cross_chain_conflicts', count(*) from case.cross_chain_conflicts
union all select 'cross_chain_tx_legs', count(*) from case.cross_chain_tx_legs
union all select 'tx_label_entries', count(*) from case.tx_label_entries
union all select 'tx_label_entry_resolution', count(*) from case.tx_label_entry_resolution
union all select 'tx_label_entry_assignments', count(*) from case.tx_label_entry_assignments
union all select 'tx_label_owner_summary', count(*) from case.tx_label_owner_summary
union all select 'normalized_transactions', count(*) from case.normalized_transactions
union all select 'transfer_base', count(*) from case.transfer_base
union all select 'deposit_transactions', count(*) from case.deposit_transactions
union all select 'deposit_exposure_by_service', count(*) from case.deposit_exposure_by_service
union all select 'dormant_asset_locations', count(*) from case.dormant_asset_locations
union all select 'theft_transactions', count(*) from case.theft_transactions
order by dataset;
```

<DataTable data={source_row_counts} title="Evidence Source Query Row Counts" search download rows=20 rowNumbers rowLines rowShading>
  <Column id=dataset title="Dataset" />
  <Column id=row_count title="Rows" />
</DataTable>

```sql qa_summary
select
  count(*) as transfer_rows,
  count(distinct tx_hash) as distinct_tx_hashes,
  sum(case when tx_is_theft then 1 else 0 end) as theft_rows,
  count(distinct case when tx_is_theft then tx_hash end) as theft_tx_hashes,
  sum(case when tx_is_cross_chain then 1 else 0 end) as cross_chain_rows,
  sum(case when tx_label_assignment_status <> 'assigned' then 1 else 0 end) as rows_not_assigned,
  sum(case when tx_label_status like 'malformed%' then 1 else 0 end) as malformed_label_rows
from case.transactions
where '${inputs.chain_filter.value}' = 'all'
   or lower(chain) = '${inputs.chain_filter.value}';
```

<DataTable data={qa_summary} title="QA Summary" rows=1 rowLines rowShading>
  <Column id=transfer_rows title="Transfer Rows" />
  <Column id=distinct_tx_hashes title="Distinct Tx Hashes" />
  <Column id=theft_rows title="Theft Rows" />
  <Column id=theft_tx_hashes title="Theft Tx Hashes" />
  <Column id=cross_chain_rows title="Cross-Chain Rows" />
  <Column id=rows_not_assigned title="Rows Not Assigned" />
  <Column id=malformed_label_rows title="Malformed Label Rows" />
</DataTable>

## Rows Needing Review

```sql issue_rows_filtered
select *
from case.issue_rows
where '${inputs.chain_filter.value}' = 'all'
   or lower(chain) = '${inputs.chain_filter.value}'
order by ts nulls last, tx_hash, transfer_row_id;
```

<DataTable data={issue_rows_filtered} title="Rows Needing Review" search download rows=20 rowNumbers rowLines rowShading>
  <Column id=transfer_row_id title="Transfer Row ID" />
  <Column id=tx_hash title="Transaction Hash" />
  <Column id=chain title="Chain" />
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

## Label Owner Coverage

```sql owner_summary_filtered
select *
from case.tx_label_owner_summary
where '${inputs.chain_filter.value}' = 'all'
   or lower(chain) = '${inputs.chain_filter.value}'
order by ambiguous_entry_count desc,
         unmatched_entry_count desc,
         malformed_entry_count desc,
         tx_hash,
         row_label_owner_id;
```

<DataTable data={owner_summary_filtered} title="Label Owner Coverage" search download rows=20 rowNumbers rowLines rowShading>
  <Column id=row_label_owner_id title="Owner ID" />
  <Column id=tx_hash title="Transaction Hash" />
  <Column id=chain title="Chain" />
  <Column id=direction title="Direction" />
  <Column id=raw_tx_label title="Raw Tx Label" />
  <Column id=entry_count title="Entries" />
  <Column id=assigned_entry_count title="Assigned Entries" />
  <Column id=ambiguous_entry_count title="Ambiguous" />
  <Column id=unmatched_entry_count title="Unmatched" />
  <Column id=malformed_entry_count title="Malformed" />
</DataTable>

## Entry Resolution Exceptions

```sql resolution_exceptions
select *
from case.tx_label_entry_resolution
where entry_resolution_status <> 'assigned'
   or ambiguous_row_count > 0
   or assigned_row_count = 0
order by tx_hash, entry_index, entry_id;
```

<DataTable data={resolution_exceptions} title="Entry Resolution Exceptions" search download rows=20 rowNumbers rowLines rowShading>
  <Column id=tx_hash title="Transaction Hash" />
  <Column id=entry_id title="Entry ID" />
  <Column id=entry_index title="Entry Index" />
  <Column id=entry_raw title="Entry" />
  <Column id=entry_scope title="Scope" />
  <Column id=entry_resolution_status title="Resolution Status" />
  <Column id=candidate_row_count title="Candidates" />
  <Column id=assigned_row_count title="Assigned" />
  <Column id=ambiguous_row_count title="Ambiguous" />
</DataTable>

## Cross-Chain Warnings

```sql cross_chain_warnings
select *
from case.cross_chain_pairs
where cc_pair_status <> 'paired'
   or cc_timing_status <> 'ok'
order by tx_cc_id;
```

<DataTable data={cross_chain_warnings} title="Cross-Chain Warnings" search download rows=20 rowNumbers rowLines rowShading>
  <Column id=tx_cc_id title="CC Group" />
  <Column id=in_tx_hash title="IN Tx Hash" />
  <Column id=in_chain title="IN Chain" />
  <Column id=in_ts title="IN Time" />
  <Column id=out_tx_hash title="OUT Tx Hash" />
  <Column id=out_chain title="OUT Chain" />
  <Column id=out_ts title="OUT Time" />
  <Column id=cc_pair_status title="Pair Status" />
  <Column id=cc_timing_status title="Timing Status" />
  <Column id=cc_timing_delta_hours title="Timing Δ Hours" />
</DataTable>

## Transfer Sample

```sql transfer_sample
select
  transfer_row_id,
  tx_hash,
  chain,
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
  tx_label_leg_applies,
  tx_label_leg_match_reason,
  from_label,
  to_label,
  asset,
  amount_value,
  stolen_amount_value,
  source_file
from case.transactions
where '${inputs.chain_filter.value}' = 'all'
   or lower(chain) = '${inputs.chain_filter.value}'
order by ts nulls last, tx_hash, transfer_row_id
limit 100;
```

<DataTable data={transfer_sample} title="Transfer Sample" search download rows=20 rowNumbers rowLines rowShading>
  <Column id=transfer_row_id title="Transfer Row ID" />
  <Column id=tx_hash title="Transaction Hash" />
  <Column id=chain title="Chain" />
  <Column id=direction title="Direction" />
  <Column id=transfer_label title="Raw Tx Label" />
  <Column id=tx_label_entry_raw title="Applied Entry" />
  <Column id=tx_label_scope title="Scope" />
  <Column id=tx_label_actions title="Actions" />
  <Column id=tx_label_counterparty title="Counterparty" />
  <Column id=tx_label_value title="Label Value" />
  <Column id=tx_label_asset title="Label Asset" />
  <Column id=tx_label_status title="Label Status" />
  <Column id=tx_label_assignment_status title="Assignment Status" />
  <Column id=tx_label_leg_applies title="Applies To This Leg" />
  <Column id=tx_label_leg_match_reason title="Assignment Reason" />
  <Column id=from_label title="From Label" />
  <Column id=to_label title="To Label" />
  <Column id=asset title="Asset" />
  <Column id=amount_value title="Transfer Value" />
  <Column id=stolen_amount_value title="Stolen Value" />
  <Column id=source_file title="Source File" />
</DataTable>

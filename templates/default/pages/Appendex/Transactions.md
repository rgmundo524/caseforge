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
  tx_hash,
  transfer_label,
  tx_label_actions,
  tx_label_counterparty,
  tx_label_value,
  tx_label_asset,
  tx_label_status,
  ts,
  direction,
  cc_match_side,
  cc_match_eligible,
  tx_label_leg_applies,
  tx_label_leg_match_reason,
  tx_label_applicable_leg_count,
  from_label,
  from_types,
  from_counterparty,
  from_dormant_value,
  from_dormant_asset,
  from_label_status,
  from_address,
  to_label,
  to_types,
  to_counterparty,
  to_dormant_value,
  to_dormant_asset,
  to_label_status,
  to_address,
  asset,
  amount_value,
  amount_usd_value,
  stolen_amount_value,
  stolen_amount_usd_value,
  tx_is_theft,
  tx_is_cross_chain,
  tx_cc_id,
  tx_cc_direction,
  time_status,
  amount_status,
  usd_status,
  source_file
from "case".transactions
where
  '${inputs.chain_filter.value}' = 'all'
  or lower(chain) = '${inputs.chain_filter.value}'
order by ts nulls last, tx_hash, direction nulls first, from_address, to_address;
```

<DataTable data={transfers_by_chain} title="Transfer Legs by Blockchain" subtitle="Filtered by Chain" search download rows=20 rowNumbers rowLines rowShading>
  <Column id=chain title="Blockchain" />
  <Column id=tx_hash title="Transaction Hash" />
  <Column id=transfer_label title="Transaction Label" />
  <Column id=tx_label_actions title="Actions" />
  <Column id=tx_label_counterparty title="Tx Counterparty" />
  <Column id=tx_label_value title="Tx Label Value" />
  <Column id=tx_label_asset title="Tx Label Asset" />
  <Column id=tx_label_status title="Tx Label Status" />
  <Column id=ts title="Date/Time" />
  <Column id=direction title="Direction" />
  <Column id=cc_match_side title="CC Match Side" />
  <Column id=cc_match_eligible title="CC Match Eligible" />
  <Column id=tx_label_leg_applies title="Label Applies To This Leg" />
  <Column id=tx_label_leg_match_reason title="Label Match Reason" />
  <Column id=tx_label_applicable_leg_count title="Applicable Legs / Tx" />
  <Column id=from_label title="Sender Label" />
  <Column id=from_types title="Sender Types" />
  <Column id=from_counterparty title="Sender Counterparty" />
  <Column id=from_dormant_value title="Sender Dormant Value" />
  <Column id=from_dormant_asset title="Sender Dormant Asset" />
  <Column id=from_label_status title="Sender Label Status" />
  <Column id=from_address title="Sender Address" />
  <Column id=to_label title="Recipient Label" />
  <Column id=to_types title="Recipient Types" />
  <Column id=to_counterparty title="Recipient Counterparty" />
  <Column id=to_dormant_value title="Recipient Dormant Value" />
  <Column id=to_dormant_asset title="Recipient Dormant Asset" />
  <Column id=to_label_status title="Recipient Label Status" />
  <Column id=to_address title="Recipient Address" />
  <Column id=asset title="Asset" />
  <Column id=amount_value title="Transfer Value" />
  <Column id=amount_usd_value title="Transfer USD Value" fmt=usd />
  <Column id=stolen_amount_value title="Stolen Value" />
  <Column id=stolen_amount_usd_value title="Stolen USD Value" fmt=usd />
  <Column id=tx_is_theft title="Theft" />
  <Column id=tx_is_cross_chain title="Cross-Chain" />
  <Column id=tx_cc_id title="CC Group" />
  <Column id=tx_cc_direction title="CC Direction" />
  <Column id=time_status title="Time Status" />
  <Column id=amount_status title="Amount Status" />
  <Column id=usd_status title="USD Status" />
  <Column id=source_file title="Source File" />
</DataTable>

## Service Deposit Address Transfers

This table shows transfer legs where the recipient label contains the `DA` type code.

```sql recipient_services
with services as (
  select
    lower(to_counterparty) as value,
    min(to_counterparty) as label
  from "case".transactions
  where
    regexp_matches(coalesce(to_types, ''), '(^|[/\\])DA($|[/\\])', 'i')
    and coalesce(to_counterparty, '') <> ''
    and (
      '${inputs.chain_filter.value}' = 'all'
      or lower(chain) = '${inputs.chain_filter.value}'
    )
  group by lower(to_counterparty)
)
select 'all' as value, 'All' as label
union all
select value, label
from services
order by label;
```

<Dropdown
  data={recipient_services}
  name=service_filter
  value=value
  label=label
  title="Recipient Service"
  defaultValue="all"
/>

```sql service_deposit_address_transfers_table
select
  ts as time,
  tx_hash as transaction,
  direction,
  transfer_label,
  tx_label_actions,
  tx_label_counterparty,
  from_label as source_address_label,
  from_address as source_address_hash,
  to_label as recipient_address_label,
  to_address as recipient_address_hash,
  to_counterparty as recipient_service,
  amount_value as crypto_value,
  asset as crypto_asset,
  amount_usd_value as usd,
  stolen_amount_value,
  stolen_amount_usd_value,
  source_file
from "case".transactions
where
  regexp_matches(coalesce(to_types, ''), '(^|[/\\])DA($|[/\\])', 'i')
  and coalesce(to_counterparty, '') <> ''
  and (
    '${inputs.chain_filter.value}' = 'all'
    or lower(chain) = '${inputs.chain_filter.value}'
  )
  and (
    '${inputs.service_filter.value}' = 'all'
    or lower(to_counterparty) = '${inputs.service_filter.value}'
  )
order by time asc, transaction;
```

<DataTable data={service_deposit_address_transfers_table} title="Service Deposit Address Transfers" subtitle="Filtered by Chain and Recipient Service" search download rows=20 rowNumbers rowLines rowShading>
  <Column id=time title="Date/Time" />
  <Column id=transaction title="Transaction Hash" />
  <Column id=direction title="Direction" />
  <Column id=transfer_label title="Transaction Label" />
  <Column id=tx_label_actions title="Actions" />
  <Column id=tx_label_counterparty title="Tx Counterparty" />
  <Column id=source_address_label title="Sender Label" />
  <Column id=source_address_hash title="Sender Address" />
  <Column id=recipient_address_label title="Recipient Label" />
  <Column id=recipient_address_hash title="Recipient Address" />
  <Column id=recipient_service title="Recipient Service" />
  <Column id=crypto_value title="Value" />
  <Column id=crypto_asset title="Asset" />
  <Column id=usd title="USD Value" fmt=usd />
  <Column id=stolen_amount_value title="Stolen Value" />
  <Column id=stolen_amount_usd_value title="Stolen USD Value" fmt=usd />
  <Column id=source_file title="Source File" />
</DataTable>

## Cross-Chain Transaction Legs

This table shows the transaction-level cross-chain legs that are actually eligible for matching. For UTXO chains, only the labeled input side or output side is aggregated.

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
  <Column id=ts title="Time" />
</DataTable>

## Cross-Chain Pairing

This table pairs `CC:{id}:IN` and `CC:{id}:OUT` transaction legs.

```sql cross_chain_pairs
select
  tx_cc_id,
  cc_pair_status,
  in_tx_count,
  out_tx_count,
  in_tx_hash,
  in_chain,
  in_asset,
  in_amount_value,
  in_amount_usd_value,
  in_label_value,
  in_label_asset,
  in_effective_match_value,
  in_effective_match_asset,
  in_counterparty,
  in_match_side,
  in_transfer_rows,
  in_ts,
  out_tx_hash,
  out_chain,
  out_asset,
  out_amount_value,
  out_amount_usd_value,
  out_label_value,
  out_label_asset,
  out_effective_match_value,
  out_effective_match_asset,
  out_counterparty,
  out_match_side,
  out_transfer_rows,
  out_ts,
  cc_timing_status,
  cc_timing_delta_hours
from "case".v_cross_chain_pairs
order by tx_cc_id;
```

<DataTable data={cross_chain_pairs} title="Cross-Chain Pairing" search download rows=20 rowNumbers rowLines rowShading>
  <Column id=tx_cc_id title="CC Group" />
  <Column id=cc_pair_status title="Pair Status" />
  <Column id=in_tx_count title="IN Tx Count" />
  <Column id=out_tx_count title="OUT Tx Count" />
  <Column id=in_tx_hash title="Input Tx Hash" />
  <Column id=in_chain title="Input Chain" />
  <Column id=in_asset title="Input Asset" />
  <Column id=in_amount_value title="Input Amount" />
  <Column id=in_amount_usd_value title="Input USD" fmt=usd />
  <Column id=in_label_value title="Input Label Value" />
  <Column id=in_label_asset title="Input Label Asset" />
  <Column id=in_effective_match_value title="Input Effective Match Value" />
  <Column id=in_effective_match_asset title="Input Effective Match Asset" />
  <Column id=in_counterparty title="Input Counterparty" />
  <Column id=in_match_side title="Input Match Side" />
  <Column id=in_transfer_rows title="Input Rows" />
  <Column id=in_ts title="Input Time" />
  <Column id=out_tx_hash title="Output Tx Hash" />
  <Column id=out_chain title="Output Chain" />
  <Column id=out_asset title="Output Asset" />
  <Column id=out_amount_value title="Output Amount" />
  <Column id=out_amount_usd_value title="Output USD" fmt=usd />
  <Column id=out_label_value title="Output Label Value" />
  <Column id=out_label_asset title="Output Label Asset" />
  <Column id=out_effective_match_value title="Output Effective Match Value" />
  <Column id=out_effective_match_asset title="Output Effective Match Asset" />
  <Column id=out_counterparty title="Output Counterparty" />
  <Column id=out_match_side title="Output Match Side" />
  <Column id=out_transfer_rows title="Output Rows" />
  <Column id=out_ts title="Output Time" />
  <Column id=cc_timing_status title="Timing Status" />
  <Column id=cc_timing_delta_hours title="Timing Delta Hours" />
</DataTable>

## Rows Needing Review

These are transfer legs where parsing or cross-chain validation produced an issue status.

```sql issue_rows
select
  ts,
  chain,
  tx_hash,
  direction,
  transfer_label,
  from_label,
  to_label,
  asset,
  amount_value,
  amount_usd_value,
  tx_label_status,
  from_label_status,
  to_label_status,
  tx_cc_id,
  tx_cc_direction,
  cc_match_eligible,
  tx_label_leg_applies,
  tx_label_leg_match_reason,
  cc_conflict_status,
  cc_timing_status,
  issue_flags,
  source_file
from "case".v_issue_rows
order by ts nulls last, tx_hash;
```

<DataTable data={issue_rows} title="Rows Needing Review" search download rows=20 rowNumbers rowLines rowShading>
  <Column id=ts title="Date/Time" />
  <Column id=chain title="Chain" />
  <Column id=tx_hash title="Transaction Hash" />
  <Column id=direction title="Direction" />
  <Column id=transfer_label title="Transaction Label" />
  <Column id=from_label title="Sender Label" />
  <Column id=to_label title="Recipient Label" />
  <Column id=asset title="Asset" />
  <Column id=amount_value title="Value" />
  <Column id=amount_usd_value title="USD Value" fmt=usd />
  <Column id=tx_label_status title="Tx Label Status" />
  <Column id=from_label_status title="Sender Label Status" />
  <Column id=to_label_status title="Recipient Label Status" />
  <Column id=tx_cc_id title="CC Group" />
  <Column id=tx_cc_direction title="CC Direction" />
  <Column id=cc_match_eligible title="CC Match Eligible" />
  <Column id=tx_label_leg_applies title="Label Applies" />
  <Column id=tx_label_leg_match_reason title="Label Match Reason" />
  <Column id=cc_conflict_status title="CC Conflict Status" />
  <Column id=cc_timing_status title="CC Timing Status" />
  <Column id=issue_flags title="Issue Flags" />
  <Column id=source_file title="Source File" />
</DataTable>

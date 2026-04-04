---
fullWidth: true
sidebar_position: 1
---

# Appendix

## Related Transactions Details
The following is a complete list of blockchain transactions involved in this investigation.

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
order by ts nulls last, tx_hash;
```

<DataTable data={transfers_by_chain} title="Transactions by Blockchain" subtitle="Filtered by Chain" search download rows=20 rowNumbers rowLines rowShading>
  <Column id=chain title="Blockchain" />
  <Column id=tx_hash title="Transaction Hash" />
  <Column id=transfer_label title="Transaction Label" />
  <Column id=tx_label_actions title="Actions" />
  <Column id=tx_label_counterparty title="Tx Counterparty" />
  <Column id=tx_label_value title="Tx Label Value" />
  <Column id=tx_label_asset title="Tx Label Asset" />
  <Column id=tx_label_status title="Tx Label Status" />
  <Column id=ts title="Date/Time" />
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

## Service Deposit Address Transactions

This table shows transactions where the recipient label contains the `DA` type code. Use the recipient service dropdown to narrow the results to a single service.

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

```sql service_deposit_address_transactions_table
select
  ts as time,
  transfer_label,
  tx_hash as transaction,
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
order by time asc;
```

<DataTable data={service_deposit_address_transactions_table} title="Service Deposit Address Transactions" subtitle="Filtered by Chain and Recipient Service" search download rows=20 rowNumbers rowLines rowShading>
  <Column id=time title="Date/Time" />
  <Column id=transfer_label title="Transaction Label" />
  <Column id=transaction title="Transaction Hash" />
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

## Cross-Chain Pairing

This table pairs `CC:{id}:IN` rows with `CC:{id}:OUT` rows so the investigation can quickly identify matched and missing bridge legs.

```sql cross_chain_pairs
select
  tx_cc_id,
  cc_pair_status,
  in_tx_hash,
  in_chain,
  in_asset,
  in_amount_value,
  in_label_value,
  in_label_asset,
  in_ts,
  out_tx_hash,
  out_chain,
  out_asset,
  out_amount_value,
  out_label_value,
  out_label_asset,
  out_ts
from "case".v_cross_chain_pairs
order by tx_cc_id;
```

<DataTable data={cross_chain_pairs} title="Cross-Chain Pairing" search download rows=20 rowNumbers rowLines rowShading>
  <Column id=tx_cc_id title="CC Group" />
  <Column id=cc_pair_status title="Pair Status" />
  <Column id=in_tx_hash title="Input Tx Hash" />
  <Column id=in_chain title="Input Chain" />
  <Column id=in_asset title="Input Asset" />
  <Column id=in_amount_value title="Input Amount" />
  <Column id=in_label_value title="Input Label Value" />
  <Column id=in_label_asset title="Input Label Asset" />
  <Column id=in_ts title="Input Time" />
  <Column id=out_tx_hash title="Output Tx Hash" />
  <Column id=out_chain title="Output Chain" />
  <Column id=out_asset title="Output Asset" />
  <Column id=out_amount_value title="Output Amount" />
  <Column id=out_label_value title="Output Label Value" />
  <Column id=out_label_asset title="Output Label Asset" />
  <Column id=out_ts title="Output Time" />
</DataTable>

## Rows Needing Review

These are rows where parsing or normalization produced an issue status. This should help investigators and operators identify malformed labels, missing timestamps, or suspicious value conditions quickly.

```sql issue_rows
select
  ts,
  chain,
  tx_hash,
  transfer_label,
  from_label,
  to_label,
  asset,
  amount_value,
  tx_label_value,
  tx_label_asset,
  tx_label_status,
  from_label_status,
  to_label_status,
  time_status,
  amount_status,
  usd_status,
  issue_flags,
  source_file
from "case".v_issue_rows
where
  '${inputs.chain_filter.value}' = 'all'
  or lower(chain) = '${inputs.chain_filter.value}'
order by ts nulls last, tx_hash;
```

<DataTable data={issue_rows} title="Rows Needing Review" search download rows=20 rowNumbers rowLines rowShading>
  <Column id=ts title="Date/Time" />
  <Column id=chain title="Chain" />
  <Column id=tx_hash title="Transaction Hash" />
  <Column id=transfer_label title="Transaction Label" />
  <Column id=from_label title="Sender Label" />
  <Column id=to_label title="Recipient Label" />
  <Column id=asset title="Asset" />
  <Column id=amount_value title="Transfer Value" />
  <Column id=tx_label_value title="Label Value" />
  <Column id=tx_label_asset title="Label Asset" />
  <Column id=tx_label_status title="Tx Label Status" />
  <Column id=from_label_status title="Sender Label Status" />
  <Column id=to_label_status title="Recipient Label Status" />
  <Column id=time_status title="Time Status" />
  <Column id=amount_status title="Amount Status" />
  <Column id=usd_status title="USD Status" />
  <Column id=issue_flags title="Issue Flags" />
  <Column id=source_file title="Source File" />
</DataTable>

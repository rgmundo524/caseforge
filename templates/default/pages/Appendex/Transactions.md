---
fullWidth: true
sidebar_position: 1
---

# Appendix

## Related Transactions Details
The following is a complete list of blockchain transactions involved in this investigation.

<!-- Generates a list of blockchains involved in the investigation and adds a combined "all" option for unfiltered selection -->
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

<!-- Renders a drop down menu referencing the above sql query results to filter for specific blockchains, defaulting to "All"-->
<Dropdown
  data={chains}
  name=chain_filter
  value=value
  label=label
  title="Chain"
  defaultValue="all"
/>

<!-- SQL query to filter results transaction by blockchain -->
```sql transfers_by_chain
select 
  upper(substr(coalesce(chain, ''), 1, 1)) || lower(substr(coalesce(chain, ''), 2)) as chain,
  tx_hash, 
  transfer_label, 
  ts, 
  from_label, 
  from_address, 
  to_label, 
  to_address, 
  amount_native, 
  asset, 
  amount_usd, 
  stolen_amount_native 
from "case".transactions
where
  '${inputs.chain_filter.value}' = 'all'
  or trim(lower(chain)) = '${inputs.chain_filter.value}'
order by ts;
```

<!-- Renders a table to display the filter/unfiltered transactions -->
<DataTable data={transfers_by_chain} title="Transactions by Blockchain" subtitle="Filtered by Chain" search download rows=20 rowNumbers rowLines rowShading>
  <Column id=chain title="Blockchain" />
  <Column id=tx_hash title="Transaction Hash" />
  <Column id=transfer_label title="Transaction Label" />
  <Column id=ts title="Date/Time" />
  <Column id=from_label title="Sender" />
  <Column id=from_address title="Sender Address" />
  <Column id=to_label title="Receiver" />
  <Column id=to_address title="Receiver Address" />
  <Column id=amount_native title="Value" />
  <Column id=asset title="Asset" />
  <Column id=amount_usd title="USD Value" fmt=usd />
  <Column id=stolen_amount_native title="Stolen Value" />
</DataTable>

## Service Deposit Address Transactions

This table shows transactions where the recipient label indicates a service deposit address. Use the recipient service dropdown to narrow the results to a single service.

<!-- Builds a dropdown list of recipient services found in service deposit address transactions for the selected chain and adds an "All" option for unfiltered results -->
```sql recipient_services
with t as (
  select
    chain,
    trim(replace(coalesce(to_label, ''), '"', '')) as to_label_raw,
    lower(trim(replace(coalesce(to_label, ''), '"', ''))) as to_label_clean,
    trim(regexp_replace(trim(replace(coalesce(to_label, ''), '"', '')), '\s*\([^)]*\)\s*$', '')) as to_label_suffix_base,
    lower(trim(regexp_replace(trim(replace(coalesce(to_label, ''), '"', '')), '\s*\([^)]*\)\s*$', ''))) as to_label_suffix_clean
  from "case".transactions
),
services as (
  select
    lower(
      case
        when to_label_clean like 'deposit address (%' then trim(split_part(split_part(to_label_raw, '(', 2), ')', 1))
        when to_label_suffix_clean like '%deposit address' then trim(left(to_label_suffix_base, length(to_label_suffix_base) - length('Deposit Address')))
        when to_label_suffix_clean like '% da' then trim(left(to_label_suffix_base, length(to_label_suffix_base) - 3))
        else ''
      end
    ) as value,
    case
      when to_label_clean like 'deposit address (%' then trim(split_part(split_part(to_label_raw, '(', 2), ')', 1))
      when to_label_suffix_clean like '%deposit address' then trim(left(to_label_suffix_base, length(to_label_suffix_base) - length('Deposit Address')))
      when to_label_suffix_clean like '% da' then trim(left(to_label_suffix_base, length(to_label_suffix_base) - 3))
      else ''
    end as label
  from t
  where
    '${inputs.chain_filter.value}' = 'all'
    or trim(lower(chain)) = '${inputs.chain_filter.value}'
)
select 'all' as value, 'All' as label
union all
select
  value,
  min(label) as label
from services
where value <> '' and label <> ''
group by value
order by label;
```

<!-- Creates a dropdown filter for recipient services using the extracted service names, defaulting to "All" -->
<Dropdown
  data={recipient_services}
  name=service_filter
  value=value
  label=label
  title="Recipient Service"
  defaultValue="all"
/>

<!-- Retrieves service deposit address transactions and filters them by the selected chain and recipient service -->
```sql service_deposit_address_transactions_table
with t as (
  select
    chain,
    ts as time,
    transfer_label,
    tx_hash as transaction,
    from_label as source_address_label,
    from_address as source_address_hash,
    to_label as recipient_address_label,
    to_address as recipient_address_hash,
    amount_native as crypto_value,
    asset as crypto_asset,
    amount_usd as usd,
    trim(replace(coalesce(to_label, ''), '"', '')) as to_label_raw,
    lower(trim(replace(coalesce(to_label, ''), '"', ''))) as to_label_clean,
    trim(regexp_replace(trim(replace(coalesce(to_label, ''), '"', '')), '\s*\([^)]*\)\s*$', '')) as to_label_suffix_base,
    lower(trim(regexp_replace(trim(replace(coalesce(to_label, ''), '"', '')), '\s*\([^)]*\)\s*$', ''))) as to_label_suffix_clean
  from "case".transactions
),
classified as (
  select
    chain,
    time,
    transfer_label,
    transaction,
    source_address_label,
    source_address_hash,
    recipient_address_label,
    recipient_address_hash,
    crypto_value,
    crypto_asset,
    usd,
    lower(
      case
        when to_label_clean like 'deposit address (%' then trim(split_part(split_part(to_label_raw, '(', 2), ')', 1))
        when to_label_suffix_clean like '%deposit address' then trim(left(to_label_suffix_base, length(to_label_suffix_base) - length('Deposit Address')))
        when to_label_suffix_clean like '% da' then trim(left(to_label_suffix_base, length(to_label_suffix_base) - 3))
        else ''
      end
    ) as recipient_service
  from t
)
select
  time,
  transfer_label,
  transaction,
  source_address_label,
  source_address_hash,
  recipient_address_label,
  recipient_address_hash,
  crypto_value,
  crypto_asset,
  usd
from classified
where
  recipient_service <> ''
  and (
    '${inputs.chain_filter.value}' = 'all'
    or trim(lower(chain)) = '${inputs.chain_filter.value}'
  )
  and (
    '${inputs.service_filter.value}' = 'all'
    or recipient_service = '${inputs.service_filter.value}'
  )
order by time asc;
```
<DataTable data={service_deposit_address_transactions_table} title="Service Deposit Address Transactions" subtitle="Filtered by Chain and Recipient Service" search download rows=20 rowNumbers rowLines rowShading>
  <Column id=time title="Date/Time" />
  <Column id=transfer_label title="Transaction Label" />
  <Column id=transaction title="Transaction Hash" />
  <Column id=source_address_label title="Sender Label" />
  <Column id=source_address_hash title="Sender Address" />
  <Column id=recipient_address_label title="Recipient Label" />
  <Column id=recipient_address_hash title="Recipient Address" />
  <Column id=crypto_value title="Value" />
  <Column id=crypto_asset title="Asset" />
  <Column id=usd title="USD Value" fmt=usd />
</DataTable>

<!--
## Theft Address Transactions

This table shows all transactions where either side is labeled as a theft address (`TA` variants).

```sql theft_address_transactions_table
with t as (
  select
    ts as time,
    transfer_label,
    tx_hash as transaction,
    from_label as source_address_label,
    from_address as source_address_hash,
    to_label as recipient_address_label,
    to_address as recipient_address_hash,
    amount_native as crypto_value,
    asset as crypto_asset,
    amount_usd as usd,
    lower(trim(replace(coalesce(from_label, ''), '"', ''))) as from_label_clean,
    lower(trim(replace(coalesce(to_label, ''), '"', ''))) as to_label_clean,
    lower(trim(replace(coalesce(address_label, ''), '"', ''))) as address_label_clean
  from "case".transactions
)
select
  time,
  transfer_label,
  transaction,
  source_address_label,
  source_address_hash,
  recipient_address_label,
  recipient_address_hash,
  crypto_value,
  crypto_asset,
  usd
from t
where
  from_label_clean like 'ta %'
  or from_label_clean like 'ta#%'
  or from_label_clean like '%theft address%'
  or to_label_clean like 'ta %'
  or to_label_clean like 'ta#%'
  or to_label_clean like '%theft address%'
  or address_label_clean like 'ta %'
  or address_label_clean like 'ta#%'
  or address_label_clean like '%theft address%'
order by time asc;
```
<!-- Transactions are not being displayed -->
<!--
<DataTable data={theft_address_transactions_table} title="Theft Address Transactions" search download rows=50 rowNumbers rowLines rowShading>
  <Column id=time title="Date/Time" />
  <Column id=transfer_label title="Transaction Label" />
  <Column id=transaction title="Transaction Hash" />
  <Column id=source_address_label title="Sender Label" />
  <Column id=source_address_hash title="Sender Address" />
  <Column id=recipient_address_label title="Recipient Label" />
  <Column id=recipient_address_hash title="Recipient Address" />
  <Column id=crypto_value title="Value" />
  <Column id=crypto_asset title="Asset" />
  <Column id=usd title="USD Value" fmt=usd />
</DataTable>
-->
## Cross-Chain Transactions

This table shows all transactions tagged as service cross-chain activity (`Service CXC` variants), plus explicit cross-chain transaction labels.

<!-- Retrieves transactions identified as cross-chain based solely on transfer_label values, including labels containing "CxC", "cross-chain", or "cross chain" -->
```sql crosschain_transactions_table
with t as (
  select
    ts as time,
    transfer_label,
    tx_hash as transaction,
    from_label as source_address_label,
    from_address as source_address_hash,
    to_label as recipient_address_label,
    to_address as recipient_address_hash,
    amount_native as crypto_value,
    asset as crypto_asset,
    amount_usd as usd,
    lower(trim(replace(coalesce(transfer_label, ''), '"', ''))) as transfer_label_clean
  from "case".transactions
)
select
  time,
  transfer_label,
  transaction,
  source_address_label,
  source_address_hash,
  recipient_address_label,
  recipient_address_hash,
  crypto_value,
  crypto_asset,
  usd
from t
where
  transfer_label_clean like '%cxc%'
  or transfer_label_clean like '%cross-chain%'
  or transfer_label_clean like '%cross chain%'
order by time asc;
```

<DataTable data={crosschain_transactions_table} title="Cross-Chain Transactions" search download rows=50 rowNumbers rowLines rowShading>
  <Column id=time title="Date/Time" />
  <Column id=transfer_label title="Transaction Label" />
  <Column id=transaction title="Transaction Hash" />
  <Column id=source_address_label title="Sender Label" />
  <Column id=source_address_hash title="Sender Address" />
  <Column id=recipient_address_label title="Recipient Label" />
  <Column id=recipient_address_hash title="Recipient Address" />
  <Column id=crypto_value title="Value" />
  <Column id=crypto_asset title="Asset" />
  <Column id=usd title="USD Value" fmt=usd />
</DataTable>

## Transfers by Service

This table aggregates transfers to labeled deposit addresses by service and asset,
filtered by the same chain dropdown above.

```sql transfers_by_service
with t as (
  select
    asset,
    amount_native,
    stolen_amount_native,
    amount_usd,
    stolen_amount_usd,
    trim(replace(coalesce(to_label, ''), '"', '')) as to_label_raw,
    lower(trim(replace(coalesce(to_label, ''), '"', ''))) as to_label_clean,
    trim(regexp_replace(trim(replace(coalesce(to_label, ''), '"', '')), '\s*\([^)]*\)\s*$', '')) as to_label_suffix_base,
    lower(trim(regexp_replace(trim(replace(coalesce(to_label, ''), '"', '')), '\s*\([^)]*\)\s*$', ''))) as to_label_suffix_clean
  from "case".transactions
  where
    '${inputs.chain_filter.value}' = 'all'
    or lower(chain) = lower('${inputs.chain_filter.value}')
),
deposits as (
  select
    case
      when to_label_clean like 'deposit address (%' then trim(split_part(split_part(to_label_raw, '(', 2), ')', 1))
      when to_label_suffix_clean like '%deposit address' then trim(left(to_label_suffix_base, length(to_label_suffix_base) - length('Deposit Address')))
      when to_label_suffix_clean like '% da' then trim(left(to_label_suffix_base, length(to_label_suffix_base) - 3))
      else null
    end as service,
    asset,
    count(*) as tx_count,
    sum(amount_native) as gross_amount_native,
    sum(stolen_amount_native) as stolen_amount_native,
    sum(amount_usd) as gross_amount_usd,
    sum(stolen_amount_usd) as stolen_amount_usd
  from t
  group by 1,2
)
select *
from deposits
where service is not null and service <> ''
order by stolen_amount_usd desc nulls last, stolen_amount_native desc;
```

<DataTable data={transfers_by_service} title="Deposits by Service" search download rows=50 rowNumbers rowLines rowShading>
  <Column id=service title="Service" />
  <Column id=asset title="Asset" />
  <Column id=tx_count title="Tx Count" />
  <Column id=gross_amount_native title="Gross Native" />
  <Column id=stolen_amount_native title="Stolen Native" />
  <Column id=gross_amount_usd title="Gross USD" fmt=usd />
  <Column id=stolen_amount_usd title="Stolen USD" fmt=usd />
</DataTable>

---

## Service Deposit Distribution (Donut)

This donut chart shows the distribution of *stolen USD* deposits by service for the selected chain.
If the selected chain is "all", it shows totals across all chains.

```sql service_donut_data
with t as (
  select
    trim(replace(coalesce(to_label, ''), '"', '')) as to_label_raw,
    lower(trim(replace(coalesce(to_label, ''), '"', ''))) as to_label_clean,
    trim(regexp_replace(trim(replace(coalesce(to_label, ''), '"', '')), '\s*\([^)]*\)\s*$', '')) as to_label_suffix_base,
    lower(trim(regexp_replace(trim(replace(coalesce(to_label, ''), '"', '')), '\s*\([^)]*\)\s*$', ''))) as to_label_suffix_clean,
    stolen_amount_usd
  from "case".transactions
  where
    '${inputs.chain_filter.value}' = 'all'
    or lower(chain) = lower('${inputs.chain_filter.value}')
),
service_totals as (
  select
    case
      when to_label_clean like 'deposit address (%' then trim(split_part(split_part(to_label_raw, '(', 2), ')', 1))
      when to_label_suffix_clean like '%deposit address' then trim(left(to_label_suffix_base, length(to_label_suffix_base) - length('Deposit Address')))
      when to_label_suffix_clean like '% da' then trim(left(to_label_suffix_base, length(to_label_suffix_base) - 3))
      else null
    end as name,
    sum(stolen_amount_usd) as value
  from t
  group by 1
)
select *
from service_totals
where name is not null and name <> ''
order by value desc;
```

<ECharts config={
  {
    tooltip: { formatter: '{b}: {c} ({d}%)' },
    series: [
      {
        type: 'pie',
        radius: ['40%', '70%'],
        avoidLabelOverlap: true,
        label: { show: true },
        labelLine: { show: true },
        data: [...service_donut_data],
      }
    ]
  }
}/>

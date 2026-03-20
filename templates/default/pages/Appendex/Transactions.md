---
fullWidth: true
sidebar_position: 1
---

# Appendix

## Transfers by Blockchain

Select a blockchain to filter the transfers table.

```sql chains
select 'all' as chain_name
union all
select distinct chain as chain_name
from "case".transactions
where chain is not null
order by 1;
```

<Dropdown
  data={chains}
  name=chain_filter
  value=chain_name
  title="Chain"
  defaultValue="all"
/>

```sql transfers_by_chain
select *
from "case".transactions
where
  '${inputs.chain_filter.value}' = 'all'
  or lower(chain) = lower('${inputs.chain_filter.value}')
order by ts;
```

<DataTable data={transfers_by_chain} title="Transactions by Blockchain" subtitle="Filtered by Chain" search download rows=50 rowNumbers rowLines rowShading>
  <column id=chain title="Blockchain" />
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

## Victim Address Transactions

This table shows all transactions where either side is labeled as a victim address (`VA` variants).

```sql victim_address_transactions_table
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
  from_label_clean like 'va %'
  or from_label_clean like 'va#%'
  or from_label_clean like '%victim address%'
  or to_label_clean like 'va %'
  or to_label_clean like 'va#%'
  or to_label_clean like '%victim address%'
  or address_label_clean like 'va %'
  or address_label_clean like 'va#%'
  or address_label_clean like '%victim address%'
order by time asc;
```

<DataTable data={victim_address_transactions_table} title="Victim Address Transactions" search download rows=50 rowNumbers rowLines rowShading>
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

## Service Deposit Address Transactions

This table shows all transactions where either side is labeled as a service deposit address (`Service DA` variants).

```sql service_deposit_address_transactions_table
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
    lower(trim(replace(coalesce(address_label, ''), '"', ''))) as address_label_clean,
    lower(trim(replace(coalesce(address_entities, ''), '"', ''))) as address_entities_clean,
    lower(trim(replace(coalesce(address_flags, ''), '"', ''))) as address_flags_clean
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
  from_label_clean like '% da'
  or from_label_clean like '%deposit address%'
  or to_label_clean like '% da'
  or to_label_clean like '%deposit address%'
  or address_label_clean like '% da'
  or address_label_clean like '%deposit address%'
  or address_entities_clean like '%deposit%'
  or address_flags_clean like '%deposit%'
order by time asc;
```

<DataTable data={service_deposit_address_transactions_table} title="Service Deposit Address Transactions" search download rows=50 rowNumbers rowLines rowShading>
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

## Cross-Chain Transactions

This table shows all transactions tagged as service cross-chain activity (`Service CXC` variants), plus explicit cross-chain transaction labels.

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
    lower(trim(replace(coalesce(from_label, ''), '"', ''))) as from_label_clean,
    lower(trim(replace(coalesce(to_label, ''), '"', ''))) as to_label_clean,
    lower(trim(replace(coalesce(address_label, ''), '"', ''))) as address_label_clean,
    lower(trim(replace(coalesce(address_entities, ''), '"', ''))) as address_entities_clean,
    lower(trim(replace(coalesce(address_flags, ''), '"', ''))) as address_flags_clean,
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
  from_label_clean like '%cxc%'
  or to_label_clean like '%cxc%'
  or address_label_clean like '%cxc%'
  or transfer_label_clean like '%cxc%'
  or transfer_label_clean like '%cross-chain%'
  or transfer_label_clean like '%cross chain%'
  or from_label_clean like '%bridge%'
  or to_label_clean like '%bridge%'
  or address_entities_clean like '%cxc%'
  or address_entities_clean like '%cross-chain%'
  or address_entities_clean like '%cross chain%'
  or address_entities_clean like '%bridge%'
  or address_flags_clean like '%cxc%'
  or address_flags_clean like '%cross-chain%'
  or address_flags_clean like '%cross chain%'
  or address_flags_clean like '%bridge%'
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
  select *
  from "case".transactions
  where
    '${inputs.chain_filter.value}' = 'all'
    or lower(chain) = lower('${inputs.chain_filter.value}')
),
deposits as (
  select
    regexp_extract(to_label, 'Deposit Address \\((.*?)\\)', 1) as service,
    asset,
    count(*) as tx_count,
    sum(amount_native) as gross_amount_native,
    sum(stolen_amount_native) as stolen_amount_native,
    sum(amount_usd) as gross_amount_usd,
    sum(stolen_amount_usd) as stolen_amount_usd
  from t
  where to_label like 'Deposit Address (%'
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
  select *
  from "case".transactions
  where
    '${inputs.chain_filter.value}' = 'all'
    or lower(chain) = lower('${inputs.chain_filter.value}')
),
service_totals as (
  select
    regexp_extract(to_label, 'Deposit Address \\((.*?)\\)', 1) as name,
    sum(stolen_amount_usd) as value
  from t
  where to_label like 'Deposit Address (%'
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

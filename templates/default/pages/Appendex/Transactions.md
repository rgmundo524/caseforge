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


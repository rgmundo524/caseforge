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
with parsed as (
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
    stolen_amount_native,
    nullif(trim(regexp_extract(trim(coalesce(transfer_label, '')), '^\[([^\]]+)\]', 1)), '') as tx_actions,
    nullif(
      trim(
        regexp_replace(
          trim(regexp_replace(trim(coalesce(transfer_label, '')), '^\[[^\]]+\]\s*', '')),
          '\s*\([^)]*\)\s*$',
          ''
        )
      ),
      ''
    ) as tx_counterparty,
    try_cast(
      replace(
        regexp_extract(
          trim(coalesce(transfer_label, '')),
          '\(([-+]?(?:[0-9][0-9,]*(?:\.[0-9]+)?|\.[0-9]+))\s+[A-Za-z0-9._-]+\)',
          1
        ),
        ',',
        ''
      ) as double
    ) as tx_traced_value_native,
    upper(
      nullif(
        trim(
          regexp_extract(
            trim(coalesce(transfer_label, '')),
            '\((?:[-+]?(?:[0-9][0-9,]*(?:\.[0-9]+)?|\.[0-9]+))\s+([A-Za-z0-9._-]+)\)',
            1
          )
        ),
        ''
      )
    ) as tx_traced_value_asset
  from "case".transactions
  where
    '${inputs.chain_filter.value}' = 'all'
    or trim(lower(chain)) = '${inputs.chain_filter.value}'
)
select
  chain,
  tx_hash,
  transfer_label,
  tx_actions,
  tx_counterparty,
  coalesce(tx_traced_value_native, stolen_amount_native) as tx_traced_value_native,
  coalesce(tx_traced_value_asset, asset) as tx_traced_value_asset,
  ts,
  from_label,
  from_address,
  to_label,
  to_address,
  amount_native,
  asset,
  amount_usd,
  stolen_amount_native
from parsed
order by ts;
```

<DataTable data={transfers_by_chain} title="Transactions by Blockchain" subtitle="Filtered by Chain" search download rows=20 rowNumbers rowLines rowShading>
  <Column id=chain title="Blockchain" />
  <Column id=tx_hash title="Transaction Hash" />
  <Column id=transfer_label title="Transaction Label" />
  <Column id=tx_actions title="Actions" />
  <Column id=tx_counterparty title="Counterparty" />
  <Column id=tx_traced_value_native title="Traced Value" />
  <Column id=tx_traced_value_asset title="Traced Asset" />
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

This table shows transactions where the recipient address label contains the `DA` type code. Use the recipient service dropdown to narrow the results to a single service.

```sql recipient_services
with parsed as (
  select
    chain,
    nullif(trim(regexp_extract(trim(coalesce(to_label, '')), '^\[([^\]]+)\]', 1)), '') as to_types,
    nullif(
      trim(
        regexp_replace(
          trim(regexp_replace(trim(coalesce(to_label, '')), '^\[[^\]]+\]\s*', '')),
          '\s*\([^)]*\)\s*$',
          ''
        )
      ),
      ''
    ) as to_counterparty
  from "case".transactions
),
services as (
  select
    lower(to_counterparty) as value,
    min(to_counterparty) as label
  from parsed
  where
    regexp_matches(coalesce(to_types, ''), '(^|[/:\\])DA($|[/:\\])', 'i')
    and coalesce(to_counterparty, '') <> ''
    and (
      '${inputs.chain_filter.value}' = 'all'
      or trim(lower(chain)) = '${inputs.chain_filter.value}'
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
with parsed as (
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
    nullif(trim(regexp_extract(trim(coalesce(to_label, '')), '^\[([^\]]+)\]', 1)), '') as to_types,
    nullif(
      trim(
        regexp_replace(
          trim(regexp_replace(trim(coalesce(to_label, '')), '^\[[^\]]+\]\s*', '')),
          '\s*\([^)]*\)\s*$',
          ''
        )
      ),
      ''
    ) as recipient_service
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
from parsed
where
  regexp_matches(coalesce(to_types, ''), '(^|[/:\\])DA($|[/:\\])', 'i')
  and coalesce(recipient_service, '') <> ''
  and (
    '${inputs.chain_filter.value}' = 'all'
    or trim(lower(chain)) = '${inputs.chain_filter.value}'
  )
  and (
    '${inputs.service_filter.value}' = 'all'
    or lower(recipient_service) = '${inputs.service_filter.value}'
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

## Cross-Chain Transactions

This table shows transactions whose transaction action block contains `CC`.

```sql crosschain_transactions_table
with parsed as (
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
    nullif(trim(regexp_extract(trim(coalesce(transfer_label, '')), '^\[([^\]]+)\]', 1)), '') as tx_actions
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
from parsed
where regexp_matches(coalesce(tx_actions, ''), '(^|[/:\\])CC($|[/:\\])', 'i')
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

This table aggregates deposits to recipient labels that contain the `DA` type code.

```sql transfers_by_service
with parsed as (
  select
    asset,
    amount_native,
    stolen_amount_native,
    amount_usd,
    stolen_amount_usd,
    nullif(trim(regexp_extract(trim(coalesce(to_label, '')), '^\[([^\]]+)\]', 1)), '') as to_types,
    nullif(
      trim(
        regexp_replace(
          trim(regexp_replace(trim(coalesce(to_label, '')), '^\[[^\]]+\]\s*', '')),
          '\s*\([^)]*\)\s*$',
          ''
        )
      ),
      ''
    ) as to_counterparty
  from "case".transactions
  where
    '${inputs.chain_filter.value}' = 'all'
    or lower(chain) = lower('${inputs.chain_filter.value}')
)
select
  to_counterparty as service,
  asset,
  count(*) as tx_count,
  sum(amount_native) as gross_amount_native,
  sum(stolen_amount_native) as stolen_amount_native,
  sum(amount_usd) as gross_amount_usd,
  sum(stolen_amount_usd) as stolen_amount_usd
from parsed
where
  regexp_matches(coalesce(to_types, ''), '(^|[/:\\])DA($|[/:\\])', 'i')
  and coalesce(to_counterparty, '') <> ''
group by 1,2
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

This donut chart shows the distribution of stolen USD deposits by service for the selected chain.

```sql service_donut_data
with parsed as (
  select
    nullif(trim(regexp_extract(trim(coalesce(to_label, '')), '^\[([^\]]+)\]', 1)), '') as to_types,
    nullif(
      trim(
        regexp_replace(
          trim(regexp_replace(trim(coalesce(to_label, '')), '^\[[^\]]+\]\s*', '')),
          '\s*\([^)]*\)\s*$',
          ''
        )
      ),
      ''
    ) as to_counterparty,
    stolen_amount_usd
  from "case".transactions
  where
    '${inputs.chain_filter.value}' = 'all'
    or lower(chain) = lower('${inputs.chain_filter.value}')
)
select
  to_counterparty as name,
  sum(stolen_amount_usd) as value
from parsed
where
  regexp_matches(coalesce(to_types, ''), '(^|[/:\\])DA($|[/:\\])', 'i')
  and coalesce(to_counterparty, '') <> ''
group by 1
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

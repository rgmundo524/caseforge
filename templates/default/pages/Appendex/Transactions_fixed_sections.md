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
  from_label_clean like '% da'
  or from_label_clean like '%deposit address%'
  or to_label_clean like '% da'
  or to_label_clean like '%deposit address%'
  or address_label_clean like '% da'
  or address_label_clean like '%deposit address%'
  or transfer_label_clean like '%deposit%'
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
  or address_label_clean like '%bridge%'
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

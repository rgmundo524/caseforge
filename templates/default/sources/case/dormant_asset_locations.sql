-- One row per dormant-asset holding location referenced in labels.
-- Guarantees at least one typed row for Evidence source extraction.
with from_side as (
  select
    transfer_row_id,
    tx_hash,
    ts,
    chain,
    format,
    'from' as side,
    from_address as address,
    from_label as label,
    from_types as types,
    from_counterparty as counterparty,
    from_dormant_value as dormant_value,
    from_dormant_asset as dormant_asset,
    source_file,
    false as __placeholder_row
  from transactions
  where from_dormant_value is not null
),
to_side as (
  select
    transfer_row_id,
    tx_hash,
    ts,
    chain,
    format,
    'to' as side,
    to_address as address,
    to_label as label,
    to_types as types,
    to_counterparty as counterparty,
    to_dormant_value as dormant_value,
    to_dormant_asset as dormant_asset,
    source_file,
    false as __placeholder_row
  from transactions
  where to_dormant_value is not null
),
actual as (
  select * from from_side
  union all
  select * from to_side
), placeholder as (
  select
    cast(null as bigint) as transfer_row_id,
    cast(null as varchar) as tx_hash,
    cast(null as timestamp) as ts,
    cast(null as varchar) as chain,
    cast(null as varchar) as format,
    cast(null as varchar) as side,
    cast(null as varchar) as address,
    cast(null as varchar) as label,
    cast(null as varchar) as types,
    cast(null as varchar) as counterparty,
    cast(null as double) as dormant_value,
    cast(null as varchar) as dormant_asset,
    cast(null as varchar) as source_file,
    true as __placeholder_row
)
select * from actual
union all
select * from placeholder
where not exists (select 1 from actual)
order by ts nulls last, tx_hash, transfer_row_id, side;

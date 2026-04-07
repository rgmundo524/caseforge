-- One row per dormant-asset holding location referenced in labels.
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
    source_file
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
    source_file
  from transactions
  where to_dormant_value is not null
)
select * from from_side
union all
select * from to_side
order by ts nulls last, tx_hash, transfer_row_id, side;

-- Shared debug surface: cross-chain labeling conflicts.
-- Guarantees at least one typed row for Evidence source extraction.
with actual as (
  select
    tx_hash,
    cc_row_count,
    eligible_row_count,
    cc_id_count,
    cc_direction_count,
    min_cc_id,
    max_cc_id,
    min_cc_direction,
    max_cc_direction,
    cc_conflict_status,
    false as __placeholder_row
  from v_cross_chain_conflicts
), placeholder as (
  select
    cast(null as varchar) as tx_hash,
    cast(null as bigint) as cc_row_count,
    cast(null as bigint) as eligible_row_count,
    cast(null as bigint) as cc_id_count,
    cast(null as bigint) as cc_direction_count,
    cast(null as integer) as min_cc_id,
    cast(null as integer) as max_cc_id,
    cast(null as varchar) as min_cc_direction,
    cast(null as varchar) as max_cc_direction,
    cast(null as varchar) as cc_conflict_status,
    true as __placeholder_row
)
select * from actual
union all
select * from placeholder
where not exists (select 1 from actual);

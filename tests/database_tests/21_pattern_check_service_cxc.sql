-- Purpose: show transaction/address labels whose parsed blocks include cross-chain markers.

with cc_matches as (
  select
    'transfer_label' as match_source,
    tx_label_actions as parsed_block,
    tx_cc_id,
    tx_cc_direction,
    tx_label_counterparty as counterparty,
    transfer_label as label_value
  from transactions
  where tx_is_cross_chain

  union all

  select
    'from_label' as match_source,
    from_types as parsed_block,
    null as tx_cc_id,
    null as tx_cc_direction,
    from_counterparty as counterparty,
    from_label as label_value
  from transactions
  where regexp_matches(upper(coalesce(from_types, '')), '(^|[/\,;: ])CC($|[/\,;: ])')

  union all

  select
    'to_label' as match_source,
    to_types as parsed_block,
    null as tx_cc_id,
    null as tx_cc_direction,
    to_counterparty as counterparty,
    to_label as label_value
  from transactions
  where regexp_matches(upper(coalesce(to_types, '')), '(^|[/\,;: ])CC($|[/\,;: ])')
)
select
  match_source,
  parsed_block,
  tx_cc_id,
  tx_cc_direction,
  counterparty,
  label_value,
  count(*) as n
from cc_matches
group by 1,2,3,4,5,6
order by match_source, n desc, counterparty, label_value;

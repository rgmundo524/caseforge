-- Purpose: show transaction/address labels whose parsed blocks include CC

with cc_matches as (
  select
    'transfer_label' as match_source,
    tx_actions as parsed_block,
    tx_counterparty as counterparty,
    transfer_label as label_value
  from transactions
  where regexp_matches(upper(coalesce(tx_actions, '')), '(^|[/\\,;: ])CC($|[/\\,;: ])')

  union all

  select
    'from_label' as match_source,
    from_types as parsed_block,
    from_counterparty as counterparty,
    from_label as label_value
  from transactions
  where regexp_matches(upper(coalesce(from_types, '')), '(^|[/\\,;: ])CC($|[/\\,;: ])')

  union all

  select
    'to_label' as match_source,
    to_types as parsed_block,
    to_counterparty as counterparty,
    to_label as label_value
  from transactions
  where regexp_matches(upper(coalesce(to_types, '')), '(^|[/\\,;: ])CC($|[/\\,;: ])')
)
select
  match_source,
  parsed_block,
  counterparty,
  label_value,
  count(*) as n
from cc_matches
group by 1,2,3,4
order by match_source, n desc, counterparty, label_value;

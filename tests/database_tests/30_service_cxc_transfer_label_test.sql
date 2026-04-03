select
  tx_actions,
  tx_counterparty,
  transfer_label,
  count(*) as n
from transactions
where regexp_matches(upper(coalesce(tx_actions, '')), '(^|[/\\,;: ])CC($|[/\\,;: ])')
group by 1,2,3
order by n desc, tx_actions, transfer_label;

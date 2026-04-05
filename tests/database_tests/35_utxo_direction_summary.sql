select
  format,
  direction,
  count(*) as transfer_rows,
  count(*) filter (where tx_is_cross_chain) as cross_chain_rows,
  count(*) filter (where cc_match_eligible) as cc_match_eligible_rows,
  sum(coalesce(amount_value, 0)) as total_amount_value
from transactions
group by 1,2
order by format, direction nulls first;

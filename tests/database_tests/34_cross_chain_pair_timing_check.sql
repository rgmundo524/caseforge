-- File: 34_cross_chain_pair_timing_check.sql
select
  tx_cc_id,
  cc_pair_status,
  cc_timing_status,
  cc_timing_delta_hours,
  in_tx_hash,
  in_chain,
  in_effective_match_value,
  in_effective_match_asset,
  in_ts,
  out_tx_hash,
  out_chain,
  out_effective_match_value,
  out_effective_match_asset,
  out_ts
from v_cross_chain_pairs
order by
  case when cc_timing_status = 'ok' then 1 else 0 end,
  tx_cc_id;

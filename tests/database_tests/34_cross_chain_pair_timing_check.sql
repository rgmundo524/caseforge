-- File: 34_cross_chain_pair_timing_check.sql
select
  tx_cc_id,
  in_tx_hash,
  out_tx_hash,
  in_ts,
  out_ts,
  cc_pair_status,
  cc_timing_status,
  cc_timing_delta_hours,
  in_effective_match_value,
  in_effective_match_asset,
  out_effective_match_value,
  out_effective_match_asset
from v_cross_chain_pairs
order by tx_cc_id;

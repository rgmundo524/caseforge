-- Feature overlay source surface: cross-chain pair overview
select
  tx_cc_id,
  in_chain,
  out_chain,
  in_tx_hash,
  out_tx_hash,
  in_asset,
  out_asset,
  in_effective_match_value,
  out_effective_match_value,
  cc_timing_status,
  cc_timing_delta_hours
from v_cross_chain_pairs
order by tx_cc_id;

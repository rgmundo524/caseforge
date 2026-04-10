-- Feature overlay source surface: cross-chain rows needing review
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
where
  coalesce(cc_timing_status, 'ok') <> 'ok'
  or in_chain is null
  or out_chain is null
  or in_tx_hash is null
  or out_tx_hash is null
order by abs(cc_timing_delta_hours) desc nulls last, tx_cc_id;

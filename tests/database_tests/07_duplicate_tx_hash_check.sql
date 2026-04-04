-- File: 07_duplicate_tx_hash_check.sql
-- Note: duplicate tx_hash values may be expected for UTXO-shaped exports.
select
  tx_hash,
  min(ts) as min_ts,
  max(ts) as max_ts,
  min(chain) as sample_chain,
  min(format) as sample_format,
  count(*) as n,
  sum(coalesce(amount_value, 0)) as summed_amount_value,
  sum(coalesce(stolen_amount_value, 0)) as summed_stolen_amount_value
from transactions
group by 1
having count(*) > 1
order by n desc, tx_hash;

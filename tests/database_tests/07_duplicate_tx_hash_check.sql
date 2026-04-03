-- File: 07_duplicate_tx_hash_check.sql
-- Note: duplicate tx_hash values may be legitimate in some exports.
-- This helps distinguish repeated hashes from repeated transfer-shapes.

select
  tx_hash,
  count(*) as row_count,
  count(
    distinct coalesce(from_address, '') || '|' ||
            coalesce(to_address, '') || '|' ||
            coalesce(asset, '') || '|' ||
            coalesce(cast(amount_native as varchar), '')
  ) as distinct_transfer_shapes
from transactions
where tx_hash is not null
group by 1
having count(*) > 1
order by row_count desc, tx_hash;

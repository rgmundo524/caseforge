-- File: 14_known_hash_validation.sql
-- Uses example hashes from the attached ETH/TRX/BTC sample exports.

select
  chain,
  ts,
  tx_hash,
  transfer_label,
  tx_actions,
  tx_counterparty,
  from_label,
  from_address,
  to_label,
  to_address,
  asset,
  amount_native,
  amount_usd
from transactions
where tx_hash in (
  '0x2d8c655766e59b62a5b6858e3ce483863902d363590c52210be665c5547f4ebb',
  '91cdf044ff3df18ce03a3bdd386980fa0206ece2842d6599814e27e15e8506db',
  'dacc7ad6cea97c6457b9397e30c6ab0849e7e4248581b4f8668a40c841d1e8b7'
)
order by ts;

select
  ts,
  tx_hash,
  direction,
  from_label,
  from_address,
  to_label,
  to_address,
  asset,
  amount_value,
  amount_usd_value,
  transfer_label,
  tx_label_actions,
  tx_cc_id,
  tx_cc_direction
from transactions
where tx_hash in (
  '0x1187434d2f99d3f0f428b7c11cdcec34a14678203b05e0ebc07e5b90f48a33c1',
  '7e1aed7155ee8131b7fc5c173279e440be04fe99f53b371729bd72370f36074c',
  'c0d7a623611c39b654379478d8694819322802d814dddd8d4f571f92f590be1d'
)
order by ts, tx_hash, direction nulls first;

-- File: 14_known_hash_validation.sql
select
  ts,
  tx_hash,
  transfer_label,
  tx_label_actions,
  tx_label_counterparty,
  from_label,
  from_address,
  to_label,
  to_address,
  asset,
  amount_value,
  amount_usd_value,
  stolen_amount_value,
  stolen_amount_usd_value,
  theft_id,
  tx_is_theft,
  tx_is_cross_chain,
  tx_cc_id,
  tx_cc_direction
from transactions
where tx_hash in (
  '0x8ad1474322f9ddd7060d37f54ef1481d357cb7efca937f4c5c4abdf5452fdfdb',
  '0d8814b612a0c48669b4f7edd76c0b92b5d1a752cb8de067f3942eb9f0d0fbd8',
  '1609b461aa45ef96c8d1eb48e06e2024b63e13092081b4007a7e4e5e34cb7030'
)
order by ts, tx_hash;

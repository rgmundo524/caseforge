PRAGMA threads=4;

CREATE OR REPLACE VIEW v_stablecoins AS
SELECT * FROM (VALUES
  ('USDT'),('USDC'),('USDM'),('RUSD'),('DAI'),('TUSD'),('FDUSD'),('USDP'),
  ('GUSD'),('LUSD'),('PYUSD'),('USDE'),('FRAX')
) AS t(asset);

CREATE OR REPLACE VIEW v_transfers AS
SELECT
  vendor,
  CASE
    WHEN vendor = 'trm' AND tx_model = 'account' THEN 'trm'
    WHEN vendor = 'trm' AND tx_model = 'utxo' THEN 'trm'
    WHEN vendor = 'qlue' AND tx_model = 'account' THEN 'qlue_account'
    WHEN vendor = 'qlue' AND tx_model = 'utxo' THEN 'qlue_utxo'
    ELSE vendor || '_' || tx_model
  END AS format,
  blockchain AS chain,
  time AS ts,
  tx AS tx_hash,
  source_address AS from_address,
  destination_address AS to_address,
  source_label AS from_label,
  destination_label AS to_label,
  NULL::VARCHAR AS address_label,
  CASE WHEN tx_model = 'utxo' THEN 'utxo' ELSE NULL END AS direction,
  upper(asset) AS asset,
  value AS amount_native,
  usd AS amount_usd,
  tx_label AS transfer_label,
  NULL::INTEGER AS theft_id,
  value AS stolen_amount_native,
  usd AS stolen_amount_usd,
  source_file
FROM normalized_combined_transactions;

CREATE OR REPLACE VIEW transactions AS
SELECT * FROM v_transfers;

CREATE OR REPLACE VIEW v_normalized_transactions AS
SELECT * FROM normalized_combined_transactions;

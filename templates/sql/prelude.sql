PRAGMA threads=4;

-- Stablecoin tickers for USD fill when USD is missing.
-- Must be persistent (not TEMP) because other views depend on it across sessions.
CREATE OR REPLACE VIEW v_stablecoins AS
SELECT * FROM (VALUES
  ('USDT'),('USDC'),('USDM'),('RUSD'),('DAI'),('TUSD'),('FDUSD'),('USDP'),
  ('GUSD'),('LUSD'),('PYUSD'),('USDE'),('FRAX')
) AS t(asset);


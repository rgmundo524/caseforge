-- Derived views for reporting and analysis.
-- NOTE: This file is included after ingest scripts.
-- It assumes:
--   - v_stablecoins exists (defined in prelude.sql)
--   - one or more v_map_* views exist (depending on manifest)
--   - v_transfers is created via the injected union below

{{V_TRANSFERS_UNION}}

-- =========================
-- Exposure by service and asset
-- =========================
-- Exposure is defined as funds sent to addresses labeled "Deposit Address (SERVICE)".
-- Account-based: recipient label is deposit address label.
-- UTXO-based: outputs (direction='out') to deposit address label are received by that address.
CREATE OR REPLACE VIEW v_exposure_by_service_asset AS
WITH deposits AS (
  -- Qlue account-based
  SELECT
    regexp_extract(to_label, 'Deposit Address \\((.*?)\\)', 1) AS service,
    asset,
    amount_native,
    amount_usd,
    stolen_amount_native,
    stolen_amount_usd
  FROM v_transfers
  WHERE format = 'qlue_account'
    AND to_label LIKE 'Deposit Address (%'

  UNION ALL

  -- Qlue UTXO-based
  SELECT
    regexp_extract(address_label, 'Deposit Address \\((.*?)\\)', 1) AS service,
    asset,
    amount_native,
    amount_usd,
    stolen_amount_native,
    stolen_amount_usd
  FROM v_transfers
  WHERE format = 'qlue_utxo'
    AND lower(direction) = 'out'
    AND address_label LIKE 'Deposit Address (%'

  UNION ALL

  -- TRM multi-chain (labels via address map)
  SELECT
    regexp_extract(to_label, 'Deposit Address \\((.*?)\\)', 1) AS service,
    asset,
    amount_native,
    amount_usd,
    stolen_amount_native,
    stolen_amount_usd
  FROM v_transfers
  WHERE format = 'trm_multi'
    AND to_label LIKE 'Deposit Address (%'
)
SELECT
  service,
  asset,
  count(*) AS tx_count,
  sum(amount_native) AS gross_amount_native,
  sum(stolen_amount_native) AS stolen_amount_native,
  sum(amount_usd) AS gross_amount_usd,
  sum(stolen_amount_usd) AS stolen_amount_usd
FROM deposits
WHERE service IS NOT NULL AND service <> ''
GROUP BY 1,2
ORDER BY stolen_amount_usd DESC NULLS LAST, stolen_amount_native DESC;

-- =========================
-- Daily flows
-- =========================
CREATE OR REPLACE VIEW v_daily_flows AS
SELECT
  chain,
  date_trunc('day', ts) AS day,
  asset,
  count(*) AS tx_count,
  sum(amount_usd) AS gross_usd,
  sum(stolen_amount_usd) AS stolen_usd
FROM v_transfers
WHERE ts IS NOT NULL
GROUP BY 1,2,3
ORDER BY day;


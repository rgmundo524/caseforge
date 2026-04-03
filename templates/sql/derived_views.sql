-- Derived views for reporting and analysis.
-- NOTE: This file is included after ingest scripts.
-- It assumes:
--   - v_stablecoins exists (defined in prelude.sql)
--   - one or more v_map_* views exist (depending on manifest)
--   - v_transfers is created via the injected union below
--
-- Label grammar expected by downstream analysis:
--   Transaction: [Actions] Counterparty Name (Traced Value Asset)
--   Address:     [Types]   Counterparty Name (Dormant Value Asset)
--
-- Examples:
--   [Theft/W] Binance (100 USDC)
--   [DA/TA] Binance (100 USDC)
--   [VE] Coinbase (100 USDC)

{{V_TRANSFERS_UNION}}

-- =========================
-- Parsed label helper view
-- =========================
CREATE OR REPLACE VIEW v_parsed_labels AS
SELECT
  *,
  NULLIF(trim(regexp_extract(trim(coalesce(transfer_label, '')), '^\[([^\]]+)\]', 1)), '') AS tx_actions,
  NULLIF(trim(regexp_extract(trim(coalesce(from_label, '')), '^\[([^\]]+)\]', 1)), '') AS from_types,
  NULLIF(trim(regexp_extract(trim(coalesce(to_label, '')), '^\[([^\]]+)\]', 1)), '') AS to_types,

  NULLIF(
    trim(
      regexp_replace(
        trim(regexp_replace(trim(coalesce(transfer_label, '')), '^\[[^\]]+\]\s*', '')),
        '\s*\([^)]*\)\s*$',
        ''
      )
    ),
    ''
  ) AS tx_counterparty,

  NULLIF(
    trim(
      regexp_replace(
        trim(regexp_replace(trim(coalesce(from_label, '')), '^\[[^\]]+\]\s*', '')),
        '\s*\([^)]*\)\s*$',
        ''
      )
    ),
    ''
  ) AS from_counterparty,

  NULLIF(
    trim(
      regexp_replace(
        trim(regexp_replace(trim(coalesce(to_label, '')), '^\[[^\]]+\]\s*', '')),
        '\s*\([^)]*\)\s*$',
        ''
      )
    ),
    ''
  ) AS to_counterparty,

  try_cast(
    replace(
      regexp_extract(
        trim(coalesce(transfer_label, '')),
        '\(([-+]?(?:[0-9][0-9,]*(?:\.[0-9]+)?|\.[0-9]+))\s+[A-Za-z0-9._-]+\)',
        1
      ),
      ',',
      ''
    ) AS DOUBLE
  ) AS tx_traced_value_native,

  upper(
    NULLIF(
      trim(
        regexp_extract(
          trim(coalesce(transfer_label, '')),
          '\((?:[-+]?(?:[0-9][0-9,]*(?:\.[0-9]+)?|\.[0-9]+))\s+([A-Za-z0-9._-]+)\)',
          1
        )
      ),
      ''
    )
  ) AS tx_traced_value_asset,

  try_cast(
    replace(
      regexp_extract(
        trim(coalesce(to_label, '')),
        '\(([-+]?(?:[0-9][0-9,]*(?:\.[0-9]+)?|\.[0-9]+))\s+[A-Za-z0-9._-]+\)',
        1
      ),
      ',',
      ''
    ) AS DOUBLE
  ) AS to_dormant_value_native,

  upper(
    NULLIF(
      trim(
        regexp_extract(
          trim(coalesce(to_label, '')),
          '\((?:[-+]?(?:[0-9][0-9,]*(?:\.[0-9]+)?|\.[0-9]+))\s+([A-Za-z0-9._-]+)\)',
          1
        )
      ),
      ''
    )
  ) AS to_dormant_value_asset
FROM v_transfers;

-- =========================
-- Exposure by service and asset
-- =========================
-- Exposure is defined as funds sent to recipient labels marked with DA.
CREATE OR REPLACE VIEW v_exposure_by_service_asset AS
SELECT
  to_counterparty AS service,
  coalesce(tx_traced_value_asset, asset) AS asset,
  count(*) AS tx_count,
  sum(amount_native) AS gross_amount_native,
  sum(stolen_amount_native) AS stolen_amount_native,
  sum(amount_usd) AS gross_amount_usd,
  sum(stolen_amount_usd) AS stolen_amount_usd
FROM v_parsed_labels
WHERE
  regexp_matches(coalesce(to_types, ''), '(^|[/:\\])DA($|[/:\\])', 'i')
  AND coalesce(to_counterparty, '') <> ''
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

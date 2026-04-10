---
title: Cross-Chain Activity
sidebar_position: 35
---

# Cross-Chain Activity

This page is added by the `cross-chain-activity` feature overlay.

It is intentionally feature-scoped:
- it does not replace the shared `cross_chain_pairs` source surface
- it adds a focused analysis page and feature-specific extracted slices

```sql pair_overview
select *
from case.cross_chain_activity_summary
order by tx_cc_id
```

```sql pair_outliers
select *
from case.cross_chain_activity_outliers
order by abs(cc_timing_delta_hours) desc nulls last, tx_cc_id
```

## Pair Overview

<DataTable data={pair_overview} search download rows=20 rowNumbers rowLines rowShading>
  <Column id=tx_cc_id title="CC ID" />
  <Column id=in_chain title="In Chain" />
  <Column id=out_chain title="Out Chain" />
  <Column id=in_tx_hash title="In Tx" />
  <Column id=out_tx_hash title="Out Tx" />
  <Column id=in_asset title="In Asset" />
  <Column id=out_asset title="Out Asset" />
  <Column id=in_effective_match_value title="In Match Value" />
  <Column id=out_effective_match_value title="Out Match Value" />
  <Column id=cc_timing_status title="Timing Status" />
  <Column id=cc_timing_delta_hours title="Timing Δ (hrs)" />
</DataTable>

## Pairs Needing Review

<DataTable data={pair_outliers} search download rows=20 rowNumbers rowLines rowShading>
  <Column id=tx_cc_id title="CC ID" />
  <Column id=in_chain title="In Chain" />
  <Column id=out_chain title="Out Chain" />
  <Column id=in_tx_hash title="In Tx" />
  <Column id=out_tx_hash title="Out Tx" />
  <Column id=cc_timing_status title="Timing Status" />
  <Column id=cc_timing_delta_hours title="Timing Δ (hrs)" />
</DataTable>

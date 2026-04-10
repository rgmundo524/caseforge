---
title: URLs
sidebar_position: 5
---

# URLs

This page is added by the `urls` feature overlay.

The current source query is a placeholder surface with the intended schema, so
you can see the feature-overlay mechanism in action before the URL ingestor exists.

```sql url_count
select count(*) as url_count
from case.url_indicators
```

```sql urls
select *
from case.url_indicators
order by observed_at desc nulls last
```

## Current URL Count

<BigValue
  data={url_count}
  value=url_count
  title="URL Indicators"
  fmt=num0
/>

## URL Indicators

<DataTable data={urls} search download rows=20 rowNumbers rowLines rowShading>
  <Column id=indicator_id title="Indicator ID" />
  <Column id=observed_url title="Observed URL" />
  <Column id=normalized_url title="Normalized URL" />
  <Column id=domain title="Domain" />
  <Column id=source_type title="Source Type" />
  <Column id=artifact_ref title="Artifact Ref" />
  <Column id=note title="Note" />
  <Column id=observed_at title="Observed At" />
</DataTable>

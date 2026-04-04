-- File: 08_timestamp_quality_check.sql
select
  count(*) as total_rows,
  count(*) filter (where ts is null) as null_ts,
  count(*) filter (where time_status <> 'ok') as non_ok_time_status_rows,
  min(ts) as min_ts,
  max(ts) as max_ts
from transactions;

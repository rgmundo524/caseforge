-- Placeholder OSINT source surface.
-- Keep one typed placeholder row so Evidence source extraction emits a valid parquet file.
select
  cast(null as varchar) as indicator_id,
  cast(null as varchar) as observed_url,
  cast(null as varchar) as normalized_url,
  cast(null as varchar) as domain,
  cast(null as varchar) as source_type,
  cast(null as varchar) as artifact_ref,
  cast(null as varchar) as note,
  cast(null as timestamp) as observed_at,
  true as __placeholder_row;

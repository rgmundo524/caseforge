-- Placeholder OSINT source surface.
-- Replace this file later with something like:
--   select * from osint_url_indicators;

select
  cast(null as varchar) as indicator_id,
  cast(null as varchar) as observed_url,
  cast(null as varchar) as normalized_url,
  cast(null as varchar) as domain,
  cast(null as varchar) as source_type,
  cast(null as varchar) as artifact_ref,
  cast(null as varchar) as note,
  cast(null as timestamp) as observed_at
where false;

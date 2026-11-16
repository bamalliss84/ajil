-- =====================================================================
-- صلاحيات مفتاح الخدمة (Edge Functions) على مخطط app
-- service_role يتجاوز RLS لكنه يحتاج صلاحيات الجداول والدوال صراحة
-- =====================================================================
do $$
begin
  if exists (select 1 from pg_roles where rolname = 'service_role') then
    grant usage on schema app to service_role;
    grant all on all tables in schema app to service_role;
    grant all on all sequences in schema app to service_role;
    grant execute on all functions in schema app to service_role;
  end if;
end $$;

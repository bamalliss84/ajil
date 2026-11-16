-- =====================================================================
-- Realtime: إشعار الجوالات الأخرى في الفرع فور أي تغيير
-- (Supabase يطبّق RLS على postgres_changes للمستخدم المتصل)
-- =====================================================================
do $$
begin
  if exists (select 1 from pg_publication where pubname = 'supabase_realtime') then
    alter publication supabase_realtime add table app.transactions, app.customers, app.promises;
  end if;
end $$;

-- القراءة المباشرة لجدول الباقات عبر العلاقة subscriptions → plans
grant select on app.plans to authenticated;

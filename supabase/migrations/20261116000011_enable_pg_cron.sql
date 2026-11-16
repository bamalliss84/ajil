-- تفعيل pg_cron (إن كانت متاحة في الخادم) وجدولة الفحص اليومي
-- migration 05 تجدول فقط إن كانت الإضافة مفعّلة مسبقاً؛ هنا نفعّلها ثم نجدول
do $$
begin
  if exists (select 1 from pg_available_extensions where name = 'pg_cron') then
    create extension if not exists pg_cron with schema pg_catalog;
    if not exists (select 1 from cron.job where jobname = 'ajil-daily-checks') then
      perform cron.schedule('ajil-daily-checks', '0 1 * * *', 'select app.run_daily_checks()');
    end if;
  else
    raise notice 'pg_cron غير متاحة — الفحص اليومي غير مجدول';
  end if;
end $$;

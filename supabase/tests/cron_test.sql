-- اختبار جدولة الفحص اليومي (migration 11)
\set QUIET on
\pset tuples_only on
\pset format unaligned
\ir _helpers.sql

select test.ok(
  not exists (select 1 from pg_available_extensions where name = 'pg_cron')
  or exists (select 1 from cron.job where jobname = 'ajil-daily-checks' and command like '%app.run_daily_checks()%'),
  'الفحص اليومي مجدول في pg_cron (إن كانت متاحة)');

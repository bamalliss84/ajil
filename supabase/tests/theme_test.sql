-- =====================================================================
-- اختبارات المظهر لكل مستخدم (migration 14)
-- =====================================================================
\set QUIET on
\pset tuples_only on
\pset format unaligned
\ir _helpers.sql

reset role;
select set_config('request.jwt.claims', '', false);

-- بقالتان: الأولى بمالك وموظف، والثانية بمالك وموظف
select app.create_store('بقالة الندى', '777600001', 'نادر', '00000000-0000-0000-0000-0000000006a1', 'dev-T1') as s1 \gset
select app.create_store('بقالة الضحى', '777600002', 'ضياء', '00000000-0000-0000-0000-0000000006b1', 'dev-T2') as s2 \gset
select id as o1 from app.app_users where store_id = :'s1' and user_no = 1 \gset
select id as o2 from app.app_users where store_id = :'s2' and user_no = 1 \gset
select id as b1 from app.branches where store_id = :'s1' \gset

select test.ok((select bool_and(theme = 'classic') from app.app_users where store_id in (:'s1', :'s2')),
  'المظهر الافتراضي لكل مستخدم: classic');

select test.login(:'s1', :'o1', 'owner');
set role authenticated;
select (app.add_employee('منى', '00000000-0000-0000-0000-0000000006e1', array[:'b1']::uuid[])).id as e1 \gset
insert into app.customers (id, store_id, branch_id, name, default_currency)
values ('ffffffff-0000-0000-0000-000000000001', :'s1', :'b1', 'زبون المظهر', 'YER');
reset role;
select test.login(:'s2', :'o2', 'owner');
set role authenticated;
select (app.add_employee('سهى', '00000000-0000-0000-0000-0000000006e2', array[]::uuid[])).id as e2 \gset
reset role;

-- ---------------------------------------------------------------------
-- set_my_theme: صف المستخدم نفسه فقط
-- ---------------------------------------------------------------------
select test.login(:'s1', :'e1', 'employee');
set role authenticated;
select test.ok(app.set_my_theme('ocean') = 'ocean', 'الموظف يغيّر مظهره');
select test.fails($$select app.set_my_theme('dark')$$, 'theme_invalid', 'قيمة غير مسموحة تُرفض');
select test.fails($$select app.set_my_theme(null)$$, 'theme_invalid', 'المظهر الفارغ يُرفض');
select test.fails($$update app.app_users set theme = 'ocean' where id = '$$ || :'o1' || $$'$$,
  'permission denied', 'لا update مباشر على المستخدمين');
reset role;
select test.ok((select theme from app.app_users where id = :'e1') = 'ocean'
           and (select theme from app.app_users where id = :'o1') = 'classic',
  'set_my_theme غيّرت صف الموظف وحده ولم تمسّ مالك بقالته');
select test.ok((select bool_and(theme = 'classic') from app.app_users where store_id = :'s2'),
  'مستخدمو بقالة أخرى لا يتأثرون');

-- توكن بلا app_user_id أو anon لا يغيّر شيئاً
select set_config('request.jwt.claims', '{"role": "authenticated"}', false);
set role authenticated;
select test.fails($$select app.set_my_theme('ocean')$$, 'not_authenticated', 'بدون مستخدم في التوكن تُرفض');
reset role;
select test.ok(not has_function_privilege('anon', 'app.set_my_theme(text)', 'execute')
           and has_function_privilege('authenticated', 'app.set_my_theme(text)', 'execute'),
  'set_my_theme للمستخدم المسجل فقط');

-- توكن موظف ببقالة مزوّرة لا يغيّر صفه (store_id لا يطابق)
select test.login(:'s2', :'e1', 'employee');
set role authenticated;
select test.fails($$select app.set_my_theme('classic')$$, 'user_not_found', 'التوكن ببقالة لا تطابق المستخدم يُرفض');
reset role;
select test.ok((select theme from app.app_users where id = :'e1') = 'ocean', 'مظهر الموظف لم يتغير بالتوكن المزوّر');

-- ---------------------------------------------------------------------
-- الكشف العام يتبع مظهر المالك لا المرسل
-- ---------------------------------------------------------------------
select test.login(:'s1', :'e1', 'employee');
set role authenticated;
select app.statement_link('ffffffff-0000-0000-0000-000000000001') as tok \gset
reset role;
select test.ok(app.public_statement(:'tok') ->> 'theme' = 'classic',
  'رابط أرسله موظف مظهره ocean يعرض مظهر المالك classic');

select test.login(:'s1', :'o1', 'owner');
set role authenticated;
select app.set_my_theme('ocean') \g /dev/null
reset role;
select test.login(:'s1', :'e1', 'employee');
set role authenticated;
select app.set_my_theme('classic') \g /dev/null
reset role;
select test.ok(app.public_statement(:'tok') ->> 'theme' = 'ocean',
  'المالك يختار ocean فيتبعه الكشف رغم أن مظهر الموظف classic');

-- موظف من بقالة أخرى يغيّر مظهره ولا يؤثر
select test.login(:'s2', :'e2', 'employee');
set role authenticated;
select app.set_my_theme('ocean') \g /dev/null
reset role;
select test.ok((select theme from app.app_users where id = :'o1') = 'ocean'
           and (select theme from app.app_users where id = :'e1') = 'classic'
           and (select theme from app.app_users where id = :'o2') = 'classic'
           and app.public_statement(:'tok') ->> 'theme' = 'ocean',
  'موظف من بقالة أخرى لا يؤثر على مستخدمي البقالة ولا على كشفها');

\echo 'كل اختبارات المظهر نجحت'

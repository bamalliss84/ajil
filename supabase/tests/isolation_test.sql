-- =====================================================================
-- اختبارات تقوية العزل (migration 12)
-- =====================================================================
\set QUIET on
\pset tuples_only on
\pset format unaligned
\ir _helpers.sql

reset role;
select set_config('request.jwt.claims', '', false);

-- ---------------------------------------------------------------------
-- التجهيز: بقالتان، الأولى بفرعين وموظف
-- ---------------------------------------------------------------------
select app.create_store('بقالة الريان', '777200001', 'عمر', '00000000-0000-0000-0000-0000000003a1', 'dev-I1') as s1 \gset
select app.create_store('بقالة السلام', '777200002', 'فهد', '00000000-0000-0000-0000-0000000003b1', 'dev-I2') as s2 \gset
select id as o1 from app.app_users where store_id = :'s1' and user_no = 1 \gset
select id as o2 from app.app_users where store_id = :'s2' and user_no = 1 \gset
select id as b1 from app.branches where store_id = :'s1' \gset
select id as b2x from app.branches where store_id = :'s2' \gset

select test.login(:'s1', :'o1', 'owner');
set role authenticated;
select (app.add_branch('فرع الشرج')).id as b1b \gset
select (app.add_employee('يوسف', '00000000-0000-0000-0000-0000000003e1', array[:'b1']::uuid[])).id as e1 \gset

-- ---------------------------------------------------------------------
-- 2) created_by يفرضه الخادم
-- ---------------------------------------------------------------------
insert into app.customers (id, store_id, branch_id, name, default_currency, created_by)
values ('88888888-0000-0000-0000-000000000001', :'s1', :'b1', 'زبون الفرع 1', 'YER', :'e1'),
       ('88888888-0000-0000-0000-000000000002', :'s1', :'b1b', 'زبون الفرع 2', 'YER', null);
select test.ok((select bool_and(created_by = :'o1') from app.customers where store_id = :'s1'),
  'created_by للزبون يأخذه الخادم من التوكن ويتجاهل قيمة الجوال (أو غيابها)');

insert into app.promises (id, store_id, branch_id, customer_id, promised_date, created_by)
values ('99999999-0000-0000-0000-000000000001', :'s1', :'b1', '88888888-0000-0000-0000-000000000001', current_date + 3, :'e1');
select test.ok((select created_by from app.promises where id = '99999999-0000-0000-0000-000000000001') = :'o1',
  'created_by للوعد يأخذه الخادم من التوكن');

-- ---------------------------------------------------------------------
-- 1) الوعد: الزبون يتبع نفس البقالة والفرع
-- ---------------------------------------------------------------------
select test.fails($$insert into app.promises (id, store_id, branch_id, customer_id, promised_date)
  values (gen_random_uuid(), '$$ || :'s1' || $$', '$$ || :'b1' || $$', '88888888-0000-0000-0000-000000000002', current_date)$$,
  'customer_mismatch', 'وعد بزبون من فرع آخر في نفس البقالة يُرفض');

reset role;
select test.login(:'s2', :'o2', 'owner');
set role authenticated;
select test.fails($$insert into app.promises (id, store_id, branch_id, customer_id, promised_date)
  values (gen_random_uuid(), '$$ || :'s2' || $$', '$$ || :'b2x' || $$', '88888888-0000-0000-0000-000000000001', current_date)$$,
  'customer_mismatch', 'وعد في بقالتي بزبون من بقالة أخرى يُرفض');
select test.fails($$insert into app.promises (id, store_id, branch_id, customer_id, promised_date)
  values (gen_random_uuid(), '$$ || :'s2' || $$', '$$ || :'b2x' || $$', gen_random_uuid(), current_date)$$,
  'customer_', 'وعد بزبون غير موجود يُرفض');

-- الاتصال المباشر (بدون JWT) يحتفظ بـ created_by المرسل (استيراد وصيانة)
reset role;
select set_config('request.jwt.claims', '', false);
insert into app.customers (id, store_id, branch_id, name, default_currency, created_by)
values ('88888888-0000-0000-0000-000000000003', :'s1', :'b1', 'زبون مستورد', 'YER', :'e1');
select test.ok((select created_by from app.customers where id = '88888888-0000-0000-0000-000000000003') = :'e1',
  'الاتصال المباشر بقاعدة البيانات يحتفظ بـ created_by');

-- ---------------------------------------------------------------------
-- 3) الموظف الموقوف يفقد الوصول فوراً رغم أن توكنه ما زال سارياً
-- ---------------------------------------------------------------------
select test.login(:'s1', :'e1', 'employee');
set role authenticated;
select test.ok((select count(*) from app.customers) = 2, 'الموظف النشط يرى زبائن فرعه');
reset role;
select test.login(:'s1', :'o1', 'owner');
set role authenticated;
select app.set_employee(:'e1', false) \g /dev/null
reset role;
select test.login(:'s1', :'e1', 'employee');
set role authenticated;
select test.ok((select count(*) from app.customers) = 0, 'الموظف الموقوف لا يرى الزبائن بتوكنه القديم');
select test.ok((select count(*) from app.branches) = 0, 'الموظف الموقوف لا يرى الفروع');
select test.ok(not app.has_branch(:'b1'), 'has_branch ترفض المستخدم الموقوف');
select test.fails($$insert into app.customers (id, store_id, branch_id, name, default_currency)
  values (gen_random_uuid(), '$$ || :'s1' || $$', '$$ || :'b1' || $$', 'بعد الإيقاف', 'YER')$$,
  'row-level security', 'الموظف الموقوف لا يضيف زبوناً');
reset role;
select test.login(:'s1', :'o1', 'owner');
set role authenticated;
select app.set_employee(:'e1', true) \g /dev/null
reset role;
select test.login(:'s1', :'e1', 'employee');
set role authenticated;
select test.ok(app.has_branch(:'b1'), 'إعادة تفعيل الموظف تعيد وصوله');
select test.ok(not app.has_branch(:'b2x'), 'has_branch لا تقبل فرع بقالة أخرى');

-- ---------------------------------------------------------------------
-- 4) توكن بلا app_role لا يمر من فحص المالك
-- ---------------------------------------------------------------------
reset role;
select set_config('request.jwt.claims',
  jsonb_build_object('store_id', :'s1', 'app_user_id', :'o1', 'role', 'authenticated')::text, false);
set role authenticated;
select test.fails($$select app.add_branch('فرع مسروق')$$, 'owner_only', 'add_branch ترفض توكناً بلا دور');
select test.fails($$select app.add_employee('دخيل', gen_random_uuid(), array[]::uuid[])$$, 'owner_only',
  'add_employee ترفض توكناً بلا دور');
select test.fails($$select app.set_device_state(gen_random_uuid(), true, false)$$, 'owner_only',
  'set_device_state ترفض توكناً بلا دور');
select test.fails($$select app.set_employee('$$ || :'e1' || $$', false)$$, 'owner_only',
  'set_employee ترفض توكناً بلا دور');
select test.fails($$select app.redeem_code('AAAA-BBBB-CCCC')$$, 'owner_only', 'redeem_code ترفض توكناً بلا دور');

-- 4ب) صلاحيات EXECUTE
reset role;
select set_config('request.jwt.claims', '', false);
select test.ok(not exists (
  select 1 from pg_proc p, aclexplode(coalesce(p.proacl, acldefault('f', p.proowner))) a
  where p.pronamespace = 'app'::regnamespace and a.privilege_type = 'EXECUTE'
    and (a.grantee = 0 or (a.grantee = 'anon'::regrole and p.proname <> 'public_statement'))),
  'لا توجد دالة في app يستطيع public أو anon تنفيذها (عدا public_statement لـ anon)');
select test.ok(not exists (
  select 1 from information_schema.role_table_grants
  where table_schema = 'app' and grantee in ('anon', 'PUBLIC')),
  'anon و public بلا أي صلاحية على جداول app');
select test.ok(not has_function_privilege('authenticated', 'app.otp_issue(text,text)', 'execute')
           and not has_function_privilege('authenticated', 'app.otp_verify(text,text,text)', 'execute')
           and not has_function_privilege('authenticated', 'app.create_store(text,text,text,uuid,text,text)', 'execute')
           and not has_function_privilege('authenticated', 'app.config(text)', 'execute')
           and not has_function_privilege('authenticated', 'app.run_daily_checks()', 'execute')
           and not has_function_privilege('authenticated', 'app.verify_chain(uuid)', 'execute')
           and not has_function_privilege('authenticated', 'app.tx_before_insert()', 'execute'),
  'المستخدم لا ينفّذ دوال الخدمة الداخلية ولا دوال الـ triggers');
select test.ok(has_function_privilege('authenticated', 'app.has_branch(uuid)', 'execute')
           and has_function_privilege('authenticated', 'app.via_gateway()', 'execute')
           and has_function_privilege('authenticated', 'app.pull_changes(uuid,bigint,integer)', 'execute')
           and has_function_privilege('authenticated', 'app.admin_summary()', 'execute'),
  'المستخدم ما زال ينفّذ دوال RLS والمزامنة ولوحة الإدارة');
select test.ok(not exists (
  select 1 from pg_proc p where p.pronamespace = 'app'::regnamespace
    and not has_function_privilege('service_role', p.oid, 'execute')),
  'مفتاح الخدمة (Edge Functions) ينفّذ كل دوال app');
select test.ok(not has_function_privilege('anon', 'public.ajil_access_token_hook(jsonb)', 'execute')
           and not has_function_privilege('authenticated', 'public.ajil_access_token_hook(jsonb)', 'execute')
           and (not exists (select 1 from pg_roles where rolname = 'supabase_auth_admin')
                or has_function_privilege('supabase_auth_admin', 'public.ajil_access_token_hook(jsonb)', 'execute')),
  'خطّاف التوكن لـ supabase_auth_admin فقط');
select test.ok((public.ajil_access_token_hook(jsonb_build_object('user_id', '00000000-0000-0000-0000-0000000003a1', 'claims', '{}'::jsonb))
  -> 'claims' ->> 'store_id') = :'s1', 'خطّاف التوكن ما زال يعمل بعد سحب الصلاحيات');

-- ---------------------------------------------------------------------
-- 5) current_subscription: بقالتي فقط
-- ---------------------------------------------------------------------
select test.login(:'s2', :'o2', 'owner');
set role authenticated;
select test.ok((select plan_code from app.current_subscription(:'s2')) = 'trial', 'المالك يقرأ اشتراك بقالته');
select test.fails($$select * from app.current_subscription('$$ || :'s1' || $$')$$, 'store_mismatch',
  'المالك لا يقرأ اشتراك بقالة أخرى');
-- الـ triggers (security definer) ما زالت تقرأ الاشتراك لبقالة المستخدم
insert into app.customers (id, store_id, branch_id, name, default_currency)
values ('88888888-0000-0000-0000-000000000004', :'s2', :'b2x', 'زبون السلام', 'YER');
select test.ok(true, 'حد الباقة في trigger الزبائن ما زال يقرأ الاشتراك');
select test.fails($$insert into app.customers (id, store_id, branch_id, name, default_currency)
  values (gen_random_uuid(), '$$ || :'s1' || $$', '$$ || :'b1' || $$', 'اختراق', 'YER')$$,
  'row-level security', 'زبون في بقالة أخرى ما زال يُرفض بـ RLS');
reset role;
select set_config('request.jwt.claims', '{"platform_admin": true, "role": "authenticated"}', false);
set role authenticated;
select test.ok((select plan_code from app.current_subscription(:'s1')) = 'trial', 'مدير المنصة يقرأ اشتراك أي بقالة');
reset role;
select set_config('request.jwt.claims', '{"role": "service_role"}', false);
set role service_role;
select plan_code as svc_plan from app.current_subscription(:'s1') \gset
reset role;
select test.ok(:'svc_plan' = 'trial', 'مفتاح الخدمة يقرأ اشتراك أي بقالة');
select set_config('request.jwt.claims', '', false);
select test.ok((select plan_code from app.current_subscription(:'s1')) = 'trial', 'الاتصال المباشر يقرأ اشتراك أي بقالة');

-- ---------------------------------------------------------------------
-- 6) مولّد عشوائي آمن: setseed لا يجعل الرموز قابلة للتوقع
-- ---------------------------------------------------------------------
select setseed(0.42) \g /dev/null
select app.otp_issue('777200101', 'register') as otp_a \gset
select setseed(0.42) \g /dev/null
select app.otp_issue('777200102', 'register') as otp_b \gset
select setseed(0.42) \g /dev/null
select app.otp_issue('777200103', 'register') as otp_c \gset
select test.ok(:'otp_a' ~ '^[0-9]{6}$' and not (:'otp_a' = :'otp_b' and :'otp_b' = :'otp_c'),
  'رمز OTP من 6 أرقام ولا يتأثر بـ setseed (لا يعتمد random())');
select setseed(0.42) \g /dev/null
select app.generate_codes('basic', 1, 1) as code_a \gset
select setseed(0.42) \g /dev/null
select app.generate_codes('basic', 1, 1) as code_b \gset
select test.ok(:'code_a' ~ '^[A-Z2-9]{4}-[A-Z2-9]{4}-[A-Z2-9]{4}$' and :'code_a' <> :'code_b',
  'أكواد التفعيل لا تتأثر بـ setseed (لا تعتمد random())');
select test.ok(pg_get_functiondef('app.otp_issue(text,text)'::regprocedure) ~ 'gen_random_bytes'
           and pg_get_functiondef('app.generate_codes(text,int,int,text)'::regprocedure) ~ 'gen_random_bytes'
           and pg_get_functiondef('app.otp_issue(text,text)'::regprocedure) !~ 'random\(\)'
           and pg_get_functiondef('app.generate_codes(text,int,int,text)'::regprocedure) !~ 'random\(\)',
  'otp_issue و generate_codes تستخدمان gen_random_bytes');

\echo 'كل اختبارات العزل نجحت'

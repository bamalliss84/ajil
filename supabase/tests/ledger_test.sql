-- =====================================================================
-- اختبارات قاعدة بيانات آجِل
-- التشغيل: psql -v ON_ERROR_STOP=1 -f supabase/tests/ledger_test.sql
-- كل اختبار يطبع ✓، وأي فشل يوقف التشغيل برسالة واضحة
-- =====================================================================
\set QUIET on
\pset tuples_only on
\pset format unaligned

\ir _helpers.sql

-- ---------------------------------------------------------------------
-- التجهيز (كمدير قاعدة البيانات)
-- ---------------------------------------------------------------------
select app.create_store('بقالة الأمانة', '777000001', 'أحمد', '00000000-0000-0000-0000-0000000000a1', 'devkey-A') as store_a \gset
select app.create_store('بقالة النور',   '777000002', 'سالم', '00000000-0000-0000-0000-0000000000b1', 'devkey-B') as store_b \gset
select id as owner_a from app.app_users where store_id = :'store_a' and user_no = 1 \gset
select id as owner_b from app.app_users where store_id = :'store_b' and user_no = 1 \gset
select id as branch_a1 from app.branches where store_id = :'store_a' \gset
select id as branch_b1 from app.branches where store_id = :'store_b' \gset

select test.ok((select count(*) = 1 from app.app_users where store_id = :'store_a' and role = 'owner' and user_no = 1),
  'إنشاء البقالة يُنشئ المالك كمستخدم رقم 1');
select test.ok((select plan_code = 'trial' and expires_at > now() + interval '29 days'
                from app.current_subscription(:'store_a')), 'البقالة الجديدة تأخذ تجربة 30 يوماً');
select test.fails($$select app.create_store('مكرر', '777000001', 'x', gen_random_uuid())$$,
  'phone_taken', 'رقم البقالة لا يُستخدم لبقالة ثانية');

-- ---------------------------------------------------------------------
-- المالك A: تسجيل الجهاز والزبون والحركات
-- ---------------------------------------------------------------------
select test.login(:'store_a', :'owner_a', 'owner');
set role authenticated;

select (app.register_device('devkey-A', 'جوال أحمد')).id as dev_a \gset
select test.ok((select approved from app.devices where id = :'dev_a'), 'جهاز المالك يُعتمد تلقائياً');

insert into app.customers (id, store_id, branch_id, name, phone, default_currency, created_by)
values ('11111111-0000-0000-0000-000000000001', :'store_a', :'branch_a1', 'محمد سالم', '777412908', 'YER', :'owner_a');

insert into app.transactions (id, store_id, branch_id, customer_id, kind, amount, currency, signed_amount, created_by, device_id, device_seq, created_at)
values
 ('22222222-0000-0000-0000-000000000001', :'store_a', :'branch_a1', '11111111-0000-0000-0000-000000000001', 'opening', 44500, 'YER', 999999, :'owner_a', :'dev_a', 1, now()),
 ('22222222-0000-0000-0000-000000000002', :'store_a', :'branch_a1', '11111111-0000-0000-0000-000000000001', 'debt',     3000, 'YER', 0, :'owner_a', :'dev_a', 2, now()),
 ('22222222-0000-0000-0000-000000000003', :'store_a', :'branch_a1', '11111111-0000-0000-0000-000000000001', 'payment', 20000, 'YER', 0, :'owner_a', :'dev_a', 3, now()),
 ('22222222-0000-0000-0000-000000000004', :'store_a', :'branch_a1', '11111111-0000-0000-0000-000000000001', 'debt',      120, 'SAR', 0, :'owner_a', :'dev_a', 4, now());

select test.ok((select signed_amount from app.transactions where id = '22222222-0000-0000-0000-000000000001') = 44500,
  'الإشارة يحسبها الخادم ويتجاهل قيمة الجوال');
select test.ok((select balance from app.customer_balances
  where customer_id = '11111111-0000-0000-0000-000000000001' and currency = 'YER') = 27500,
  'رصيد اليمني = 44,500 + 3,000 − 20,000 = 27,500');
select test.ok((select balance from app.customer_balances
  where customer_id = '11111111-0000-0000-0000-000000000001' and currency = 'SAR') = 120,
  'رصيد السعودي منفصل = 120');

-- الإلغاء (قيد عكسي)
insert into app.transactions (id, store_id, branch_id, customer_id, kind, amount, currency, signed_amount, voided_id, void_reason, created_by, device_id, device_seq, created_at)
values ('22222222-0000-0000-0000-000000000005', :'store_a', :'branch_a1', '11111111-0000-0000-0000-000000000001', 'void', 1, 'YER', 0,
        '22222222-0000-0000-0000-000000000002', 'خطأ في المبلغ', :'owner_a', :'dev_a', 5, now());
select test.ok((select balance from app.customer_balances
  where customer_id = '11111111-0000-0000-0000-000000000001' and currency = 'YER') = 24500,
  'إلغاء دين 3,000 ينزل الرصيد إلى 24,500 (المبلغ يؤخذ من الأصل)');

select test.fails($$insert into app.transactions (id, store_id, branch_id, customer_id, kind, amount, currency, signed_amount, voided_id, void_reason, created_by, device_id, device_seq, created_at)
  select gen_random_uuid(), store_id, branch_id, customer_id, 'void', 1, 'YER', 0, '22222222-0000-0000-0000-000000000002', 'مرة ثانية', created_by, device_id, 6, now()
  from app.transactions where id = '22222222-0000-0000-0000-000000000005'$$,
  'transactions_single_void', 'الحركة لا تُلغى مرتين');
select test.fails($$insert into app.transactions (id, store_id, branch_id, customer_id, kind, amount, currency, signed_amount, voided_id, void_reason, created_by, device_id, device_seq, created_at)
  select gen_random_uuid(), store_id, branch_id, customer_id, 'void', 1, 'YER', 0, id, 'x', created_by, device_id, 7, now()
  from app.transactions where id = '22222222-0000-0000-0000-000000000005'$$,
  'void_of_void', 'لا يمكن إلغاء الإلغاء');
select test.fails($$insert into app.transactions (id, store_id, branch_id, customer_id, kind, amount, currency, signed_amount, voided_id, created_by, device_id, device_seq, created_at)
  select gen_random_uuid(), store_id, branch_id, customer_id, 'void', 1, 'YER', 0, '22222222-0000-0000-0000-000000000003', created_by, device_id, 8, now()
  from app.transactions where id = '22222222-0000-0000-0000-000000000005'$$,
  'void_reason_required', 'سبب الإلغاء إلزامي');
select test.fails($$update app.transactions set amount = 1 where id = '22222222-0000-0000-0000-000000000003'$$,
  'permission denied', 'المستخدم لا يملك صلاحية تعديل الحركات');
select test.fails($$delete from app.transactions where id = '22222222-0000-0000-0000-000000000003'$$,
  'permission denied', 'المستخدم لا يملك صلاحية حذف الحركات');
select test.fails($$delete from app.customers where id = '11111111-0000-0000-0000-000000000001'$$,
  'permission denied', 'الزبون لا يُحذف (أرشفة فقط)');
select test.fails($$insert into app.transactions (id, store_id, branch_id, customer_id, kind, amount, currency, signed_amount, created_by, device_id, device_seq, created_at)
  values (gen_random_uuid(), '$$ || :'store_a' || $$', '$$ || :'branch_a1' || $$', '11111111-0000-0000-0000-000000000001', 'debt', 50, 'USD', 0, '$$ || :'owner_a' || $$', '$$ || :'dev_a' || $$', 9, now())$$,
  'currency_not_enabled', 'عملة غير مفعلة في البقالة تُرفض');

-- المزامنة: رفع آمن للتكرار، وكشف الفجوات
select string_agg(status, ',' order by status) as push1 from app.push_transactions(:'dev_a',
  jsonb_build_array(
    jsonb_build_object('id','33333333-0000-0000-0000-000000000001','branch_id',:'branch_a1','customer_id','11111111-0000-0000-0000-000000000001','kind','debt','amount',12500,'currency','YER','device_seq',10),
    jsonb_build_object('id','33333333-0000-0000-0000-000000000002','branch_id',:'branch_a1','customer_id','11111111-0000-0000-0000-000000000001','kind','debt','amount',100,'currency','USD','device_seq',12))) \gset
select test.ok(:'push1' = 'accepted,rejected', 'الرفع يقبل الصحيح ويرفض الخاطئ بسبب واضح دون إيقاف الدفعة');
select string_agg(status, ',') as push2 from app.push_transactions(:'dev_a',
  jsonb_build_array(jsonb_build_object('id','33333333-0000-0000-0000-000000000001','branch_id',:'branch_a1','customer_id','11111111-0000-0000-0000-000000000001','kind','debt','amount',12500,'currency','YER','device_seq',10))) \gset
select test.ok(:'push2' = 'duplicate', 'إعادة رفع نفس الحركة لا تكررها');
select test.ok((select array_agg(missing_seq order by missing_seq) from app.device_gaps(:'dev_a')) = array[6,7,8,9]::bigint[],
  'كشف الأرقام الناقصة في تسلسل الجهاز (6–9)');
select test.ok((app.pull_changes(:'branch_a1', 0) -> 'transactions') is not null
  and jsonb_array_length(app.pull_changes(:'branch_a1', 0) -> 'transactions') = 6,
  'السحب يرجع كل حركات الفرع');
select (app.pull_changes(:'branch_a1', 0) ->> 'max_seq') as seq_now \gset
select test.ok(jsonb_array_length(app.pull_changes(:'branch_a1', :'seq_now') -> 'transactions') = 0,
  'السحب بعد آخر مؤشر لا يرجع شيئاً');

-- فرع ثانٍ وموظف مقيّد به
select (app.add_branch('فرع السوق')).id as branch_a2 \gset
reset role;
select test.login(:'store_a', :'owner_a', 'owner');
set role authenticated;
select (app.add_employee('خالد', '00000000-0000-0000-0000-0000000000e1', array[:'branch_a2']::uuid[])).id as emp_a \gset
select test.ok((select user_no from app.app_users where id = :'emp_a') = 2, 'الموظف يأخذ رقم المستخدم 2');
insert into app.customers (id, store_id, branch_id, name, default_currency, created_by)
values ('11111111-0000-0000-0000-000000000002', :'store_a', :'branch_a2', 'زبون فرع السوق', 'YER', :'owner_a');

-- ---------------------------------------------------------------------
-- الموظف: يرى فرعه فقط
-- ---------------------------------------------------------------------
reset role;
select test.login(:'store_a', :'emp_a', 'employee');
set role authenticated;
select test.ok((select count(*) from app.customers) = 1, 'الموظف يرى زبائن فرعه فقط');
select test.ok((select count(*) from app.transactions) = 0, 'الموظف لا يرى حركات فرع آخر');
select test.fails($$insert into app.transactions (id, store_id, branch_id, customer_id, kind, amount, currency, signed_amount, created_by, device_id, device_seq, created_at)
  values (gen_random_uuid(), '$$ || :'store_a' || $$', '$$ || :'branch_a2' || $$', '11111111-0000-0000-0000-000000000002', 'debt', 500, 'YER', 0, '$$ || :'emp_a' || $$', gen_random_uuid(), 50, now())$$,
  'row-level security', 'حركة من جهاز غير مسجل في البقالة تُرفض');
select (app.register_device('devkey-emp', 'جوال خالد')).id as dev_e \gset
select test.ok((select count(*) from app.devices where id = :'dev_e') = 0, 'جهاز الموظف ينتظر اعتماد المالك ولا يظهر له');

reset role;
select test.login(:'store_a', :'owner_a', 'owner');
set role authenticated;
select test.ok((app.set_device_state(:'dev_e', true, false)).approved, 'المالك يعتمد جهاز الموظف');

reset role;
select test.login(:'store_a', :'emp_a', 'employee');
set role authenticated;
insert into app.transactions (id, store_id, branch_id, customer_id, kind, amount, currency, signed_amount, created_by, device_id, device_seq, created_at)
values ('44444444-0000-0000-0000-000000000001', :'store_a', :'branch_a2', '11111111-0000-0000-0000-000000000002', 'debt', 500, 'YER', 0, :'emp_a', :'dev_e', 1, now());
select test.ok((select balance from app.customer_balances where customer_id = '11111111-0000-0000-0000-000000000002') = 500,
  'الموظف يسجل ديناً من جهازه المعتمد');

-- الموظف يلغي حركاته فقط
reset role;
select test.login(:'store_a', :'owner_a', 'owner');
set role authenticated;
insert into app.transactions (id, store_id, branch_id, customer_id, kind, amount, currency, signed_amount, created_by, device_id, device_seq, created_at)
values ('44444444-0000-0000-0000-000000000002', :'store_a', :'branch_a2', '11111111-0000-0000-0000-000000000002', 'debt', 700, 'YER', 0, :'owner_a', :'dev_a', 20, now());
reset role;
select test.login(:'store_a', :'emp_a', 'employee');
set role authenticated;
select test.fails($$insert into app.transactions (id, store_id, branch_id, customer_id, kind, amount, currency, signed_amount, voided_id, void_reason, created_by, device_id, device_seq, created_at)
  values (gen_random_uuid(), '$$ || :'store_a' || $$', '$$ || :'branch_a2' || $$', '11111111-0000-0000-0000-000000000002', 'void', 1, 'YER', 0, '44444444-0000-0000-0000-000000000002', 'خطأ', '$$ || :'emp_a' || $$', '$$ || :'dev_e' || $$', 2, now())$$,
  'void_not_owner', 'الموظف لا يلغي حركة سجلها غيره');
insert into app.transactions (id, store_id, branch_id, customer_id, kind, amount, currency, signed_amount, voided_id, void_reason, created_by, device_id, device_seq, created_at)
values (gen_random_uuid(), :'store_a', :'branch_a2', '11111111-0000-0000-0000-000000000002', 'void', 1, 'YER', 0, '44444444-0000-0000-0000-000000000001', 'خطأ', :'emp_a', :'dev_e', 3, now());
select test.ok((select balance from app.customer_balances where customer_id = '11111111-0000-0000-0000-000000000002') = 700,
  'الموظف يلغي حركته خلال المهلة');

-- ---------------------------------------------------------------------
-- بقالة B: عزل كامل
-- ---------------------------------------------------------------------
reset role;
select test.login(:'store_b', :'owner_b', 'owner');
set role authenticated;
select test.ok((select count(*) from app.customers) = 0, 'بقالة B لا ترى زبائن A');
select test.ok((select count(*) from app.transactions) = 0, 'بقالة B لا ترى حركات A');
select test.ok((select count(*) from app.customer_balances) = 0, 'بقالة B لا ترى أرصدة A');
select test.fails($$insert into app.customers (id, store_id, branch_id, name, default_currency) values (gen_random_uuid(), '$$ || :'store_a' || $$', '$$ || :'branch_a1' || $$', 'اختراق', 'YER')$$,
  'row-level security', 'بقالة B لا تضيف زبوناً في A');
select test.fails($$select app.register_device('devkey-A')$$, 'device_bound_elsewhere',
  'جهاز مسجل لبقالة A لا يُستخدم لبقالة B قبل إلغائه');

-- إلغاء جهاز A يمنعه من التسجيل
reset role;
select test.login(:'store_a', :'owner_a', 'owner');
set role authenticated;
select app.set_device_state(:'dev_e', false, true) \g /dev/null
reset role;
select test.login(:'store_a', :'emp_a', 'employee');
set role authenticated;
select test.fails($$insert into app.transactions (id, store_id, branch_id, customer_id, kind, amount, currency, signed_amount, created_by, device_id, device_seq, created_at)
  values (gen_random_uuid(), '$$ || :'store_a' || $$', '$$ || :'branch_a2' || $$', '11111111-0000-0000-0000-000000000002', 'debt', 1, 'YER', 0, '$$ || :'emp_a' || $$', '$$ || :'dev_e' || $$', 4, now())$$,
  'row-level security', 'الجهاز الملغى يُرفض فوراً');

-- ---------------------------------------------------------------------
-- حد الباقة والاشتراك
-- ---------------------------------------------------------------------
reset role;
select set_config('request.jwt.claims', '', false);
insert into app.plans (code, name_ar, customers_limit, devices_limit) values ('tiny', 'اختبار', 2, 5);
select app.activate_subscription(:'store_a', 'tiny', 1) \g /dev/null
select test.ok((select plan_code from app.current_subscription(:'store_a')) = 'tiny', 'التفعيل اليدوي من مدير المنصة');
select test.login(:'store_a', :'owner_a', 'owner');
set role authenticated;
insert into app.customers (id, store_id, branch_id, name, default_currency) values (gen_random_uuid(), :'store_a', :'branch_a1', 'زبون 2', 'YER');
select test.fails($$insert into app.customers (id, store_id, branch_id, name, default_currency) values (gen_random_uuid(), '$$ || :'store_a' || $$', '$$ || :'branch_a1' || $$', 'زبون 3', 'YER')$$,
  'plan_customer_limit', 'حد الباقة يمنع إضافة زبون فوق الحد');
update app.customers set status = 'archived' where name = 'زبون 2';
insert into app.customers (id, store_id, branch_id, name, default_currency) values (gen_random_uuid(), :'store_a', :'branch_a1', 'زبون 3', 'YER');
select test.ok(true, 'أرشفة زبون تفتح مكاناً ضمن حد الباقة');
select test.fails($$select app.activate_subscription('$$ || :'store_a' || $$', 'premium', 12)$$,
  'platform_admin_only', 'صاحب البقالة لا يفعّل اشتراكه بنفسه');
reset role;

select set_config('request.jwt.claims', '', false);
select app.create_store('بقالة مكررة', '777000003', 'س', gen_random_uuid(), 'devkey-A') as store_c \gset
select test.ok((select expires_at < now() from app.current_subscription(:'store_c')),
  'جهاز أخذ التجربة سابقاً لا يحصل على تجربة ثانية');

-- ---------------------------------------------------------------------
-- سلامة السجل: البصمات والأرصدة
-- ---------------------------------------------------------------------
select test.ok((select ok from app.verify_chain(:'branch_a1')), 'سلسلة البصمات سليمة');
select test.ok((select count(*) = 0 from app.balance_mismatches()), 'كل الأرصدة المخزّنة تطابق مجموع الحركات');

-- محاكاة تلاعب مباشر في قاعدة البيانات (حتى بصلاحية المدير)
alter table app.transactions disable trigger tx_no_update;
update app.transactions set amount = 1 where id = '22222222-0000-0000-0000-000000000003';
alter table app.transactions enable trigger tx_no_update;
select test.ok((select not ok and broken_at = '22222222-0000-0000-0000-000000000003' from app.verify_chain(:'branch_a1')),
  'أي تعديل خفي يكسر سلسلة البصمات ويحدد الحركة المعدّلة');

\echo
\echo 'كل الاختبارات نجحت'

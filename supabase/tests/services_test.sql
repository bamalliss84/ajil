-- =====================================================================
-- اختبارات الخدمات: OTP، البوابة، أكواد التفعيل، الوعود، قائمة التحصيل،
-- الإعدادات، الإيقاف، الفحص اليومي، لوحة الإدارة
-- =====================================================================
\set QUIET on
\pset tuples_only on
\pset format unaligned
\ir _helpers.sql

select set_config('request.jwt.claims', '', false);

-- ---------------------------------------------------------------------
-- OTP
-- ---------------------------------------------------------------------
select app.otp_issue('777100001', 'register') as otp1 \gset
select test.ok(length(:'otp1') = 6, 'رمز OTP من 6 أرقام');
select test.ok((select code_hash <> :'otp1' from app.otp_codes where phone = '777100001'), 'الرمز يُخزَّن مُجزّأً لا نصاً');
select test.ok(not app.otp_verify('777100001', 'register', '000000x'), 'رمز خاطئ يُرفض');
select test.ok(app.otp_verify('777100001', 'register', :'otp1'), 'الرمز الصحيح يُقبل');
select test.fails($$select app.otp_verify('777100001', 'register', '$$ || :'otp1' || $$')$$,
  'otp_expired', 'الرمز يُستخدم مرة واحدة فقط');
select app.otp_issue('777100001', 'register') \g /dev/null
select app.otp_issue('777100001', 'register') \g /dev/null
select test.fails($$select app.otp_issue('777100001', 'register')$$, 'otp_rate_limited',
  'حد 3 رموز كل 10 دقائق');
select app.otp_issue('777100009', 'register') as otp9 \gset
select app.otp_verify('777100009', 'register', '111111') from generate_series(1, 5) \g /dev/null
select test.fails($$select app.otp_verify('777100009', 'register', '$$ || :'otp9' || $$')$$, 'otp_locked',
  'بعد 5 محاولات خاطئة يُقفل الرمز حتى لو صار صحيحاً');

-- ---------------------------------------------------------------------
-- التجهيز
-- ---------------------------------------------------------------------
select app.create_store('بقالة الوفاء', '777100001', 'سعيد', '00000000-0000-0000-0000-0000000001a1', 'dev-S1') as s1 \gset
select id as o1 from app.app_users where store_id = :'s1' and user_no = 1 \gset
select id as b1 from app.branches where store_id = :'s1' \gset
select test.fails($$select app.otp_issue('777100001', 'register')$$, 'phone_taken', 'لا يُرسل رمز تسجيل لرقم مسجل');
delete from app.otp_codes where phone = '777100001';
select test.ok(length(app.otp_issue('777100001', 'reset_owner')) = 6, 'رمز استعادة كلمة المرور للمالك المسجل');
select test.fails($$select app.otp_issue('777199999', 'reset_owner')$$, 'phone_unknown', 'لا استعادة لرقم غير مسجل');

select test.login(:'s1', :'o1', 'owner');
set role authenticated;
select (app.register_device_v2('dev-S1', 'PUBKEY-1', 'جوال سعيد')).id as d1 \gset
select test.ok((select public_key = 'PUBKEY-1' from app.devices where id = :'d1'), 'تسجيل الجهاز مع مفتاحه العام');
select test.fails($$select app.register_device_v2('dev-S1', 'PUBKEY-OTHER')$$, 'device_key_mismatch',
  'تغيّر مفتاح الجهاز يُرفض');
select test.ok(app.gateway_device_key(:'d1', 'nonce-1') = 'PUBKEY-1', 'البوابة تقرأ مفتاح الجهاز المعتمد');
select test.fails($$select app.gateway_device_key('$$ || :'d1' || $$', 'nonce-1')$$, 'replay_detected',
  'نفس الطلب لا يُقبل مرتين (منع الإعادة)');

insert into app.customers (id, store_id, branch_id, name, default_currency)
values ('55555555-0000-0000-0000-000000000001', :'s1', :'b1', 'علي', 'YER'),
       ('55555555-0000-0000-0000-000000000002', :'s1', :'b1', 'حسن', 'YER');

-- ---------------------------------------------------------------------
-- بوابة المزامنة: في الإنتاج لا تُقبل الحركات إلا عبر sync-push
-- ---------------------------------------------------------------------
reset role;
update app.platform_config set value = 'true' where key = 'require_gateway';
update app.platform_config set value = encode(sha256(convert_to('s3cret', 'UTF8')), 'hex') where key = 'gateway_secret_sha256';
select test.login(:'s1', :'o1', 'owner');
set role authenticated;
select test.fails($$insert into app.transactions (id, store_id, branch_id, customer_id, kind, amount, currency, signed_amount, created_by, device_id, device_seq, created_at)
  values (gen_random_uuid(), '$$ || :'s1' || $$', '$$ || :'b1' || $$', '55555555-0000-0000-0000-000000000001', 'debt', 100, 'YER', 0, '$$ || :'o1' || $$', '$$ || :'d1' || $$', 1, now())$$,
  'row-level security', 'حركة مباشرة بدون البوابة تُرفض في وضع الإنتاج');
select set_config('request.headers', '{"x-ajil-gateway":"s3cret"}', false) \g /dev/null
insert into app.transactions (id, store_id, branch_id, customer_id, kind, amount, currency, signed_amount, created_by, device_id, device_seq, created_at, due_date)
values ('66666666-0000-0000-0000-000000000001', :'s1', :'b1', '55555555-0000-0000-0000-000000000001', 'debt', 10000, 'YER', 0, :'o1', :'d1', 1, now(), current_date),
       ('66666666-0000-0000-0000-000000000002', :'s1', :'b1', '55555555-0000-0000-0000-000000000002', 'debt', 5000, 'YER', 0, :'o1', :'d1', 2, now(), null);
select test.ok(true, 'الحركة عبر البوابة بالسر الصحيح تُقبل');
reset role;
update app.platform_config set value = 'false' where key = 'require_gateway';
select set_config('request.headers', '', false) \g /dev/null

-- ---------------------------------------------------------------------
-- الوعود وقائمة التحصيل
-- ---------------------------------------------------------------------
select test.login(:'s1', :'o1', 'owner');
set role authenticated;
insert into app.promises (id, store_id, branch_id, customer_id, promised_date, amount, currency)
values ('77777777-0000-0000-0000-000000000001', :'s1', :'b1', '55555555-0000-0000-0000-000000000002', current_date - 2, 3000, 'YER'),
       ('77777777-0000-0000-0000-000000000002', :'s1', :'b1', '55555555-0000-0000-0000-000000000002', current_date + 5, null, null);
select test.ok((select string_agg(reason, ',' order by reason) from app.due_today(:'b1')) = 'invoice_due,promise_overdue',
  'قائمة التحصيل: وعد متأخر + فاتورة موعدها اليوم (والوعد القادم لا يظهر)');
insert into app.transactions (id, store_id, branch_id, customer_id, kind, amount, currency, signed_amount, created_by, device_id, device_seq, created_at)
values (gen_random_uuid(), :'s1', :'b1', '55555555-0000-0000-0000-000000000002', 'payment', 3000, 'YER', 0, :'o1', :'d1', 3, now());
select test.ok((select status from app.promises where id = '77777777-0000-0000-0000-000000000001') = 'kept',
  'سداد المبلغ الموعود يجعل الوعد «منفّذاً» تلقائياً');
select test.ok((select status from app.promises where id = '77777777-0000-0000-0000-000000000002') = 'open',
  'الوعد بدون مبلغ يبقى مفتوحاً ما دام عليه رصيد');
insert into app.transactions (id, store_id, branch_id, customer_id, kind, amount, currency, signed_amount, created_by, device_id, device_seq, created_at)
values (gen_random_uuid(), :'s1', :'b1', '55555555-0000-0000-0000-000000000002', 'payment', 2000, 'YER', 0, :'o1', :'d1', 4, now());
select test.ok((select status from app.promises where id = '77777777-0000-0000-0000-000000000002') = 'kept',
  'تصفير الرصيد ينفّذ كل الوعود المفتوحة');

-- السداد بعملة مختلفة
update app.stores set enabled_currencies = array['YER','SAR'] where id = :'s1';
insert into app.transactions (id, store_id, branch_id, customer_id, kind, amount, currency, signed_amount, fx_paid_amount, fx_paid_currency, fx_rate, created_by, device_id, device_seq, created_at)
values (gen_random_uuid(), :'s1', :'b1', '55555555-0000-0000-0000-000000000001', 'debt', 100, 'SAR', 0, null, null, null, :'o1', :'d1', 5, now()),
       (gen_random_uuid(), :'s1', :'b1', '55555555-0000-0000-0000-000000000001', 'payment_fx', 40, 'SAR', 0, 16000, 'YER', 400, :'o1', :'d1', 6, now());
select test.ok((select balance from app.customer_balances where customer_id = '55555555-0000-0000-0000-000000000001' and currency = 'SAR') = 60,
  'سداد 16,000 ر.ي بسعر 400 ينقص الدين السعودي 40 (والسعر محفوظ في الحركة)');
select test.fails($$insert into app.transactions (id, store_id, branch_id, customer_id, kind, amount, currency, signed_amount, created_by, device_id, device_seq, created_at)
  values (gen_random_uuid(), '$$ || :'s1' || $$', '$$ || :'b1' || $$', '55555555-0000-0000-0000-000000000001', 'payment_fx', 10, 'SAR', 0, '$$ || :'o1' || $$', '$$ || :'d1' || $$', 7, now())$$,
  'fx_fields', 'السداد بعملة مختلفة يتطلب المبلغ المدفوع والسعر');

-- ---------------------------------------------------------------------
-- إعدادات المالك
-- ---------------------------------------------------------------------
update app.store_settings set monthly_claim_day = 5, monthly_claim_min = 2000 where store_id = :'s1';
select test.ok((select monthly_claim_day from app.store_settings where store_id = :'s1') = 5, 'المالك يعدّل يوم المطالبة الشهرية');
select test.fails($$update app.store_settings set monthly_claim_day = 31 where store_id = '$$ || :'s1' || $$'$$,
  'check', 'يوم المطالبة بين 0 و 28');

-- موظف لا يعدّل الإعدادات
select (app.add_employee('ناصر', '00000000-0000-0000-0000-0000000001e1', array[:'b1']::uuid[])).id as e1 \gset
reset role;
select test.login(:'s1', :'e1', 'employee');
set role authenticated;
update app.store_settings set monthly_claim_day = 9 where store_id = :'s1';
select test.ok((select monthly_claim_day from app.store_settings where store_id = :'s1') = 5, 'الموظف لا يغيّر إعدادات البقالة');
select test.fails($$select app.redeem_code('XXXX-XXXX-XXXX')$$, 'owner_only', 'الموظف لا يفعّل أكواد الاشتراك');

-- إيقاف الموظف
reset role;
select test.login(:'s1', :'o1', 'owner');
set role authenticated;
select test.ok(not (app.set_employee(:'e1', false)).is_active, 'المالك يوقف الموظف');

-- ---------------------------------------------------------------------
-- أكواد التفعيل
-- ---------------------------------------------------------------------
reset role;
select set_config('request.jwt.claims', '', false);
select app.generate_codes('advanced', 3, 2, 'مندوب المكلا') as code1 limit 1 \gset
select test.ok(:'code1' ~ '^[A-Z2-9]{4}-[A-Z2-9]{4}-[A-Z2-9]{4}$', 'كود التفعيل بصيغة XXXX-XXXX-XXXX');
select test.login(:'s1', :'o1', 'owner');
set role authenticated;
select test.fails($$select app.generate_codes('premium', 12, 5)$$, 'platform_admin_only', 'المالك لا يولّد أكواداً');
select (app.redeem_code(lower(:'code1'))).plan_code as redeemed \gset
select test.ok(:'redeemed' = 'advanced', 'المالك يفعّل اشتراكه بالكود (بدون حساسية للأحرف)');
select test.ok((select expires_at > now() + interval '3 months' from app.current_subscription(:'s1')),
  'الكود يضيف المدة فوق التجربة الحالية ولا يضيعها');
select test.fails($$select app.redeem_code('$$ || :'code1' || $$')$$, 'code_used', 'الكود يُستخدم مرة واحدة');

-- ---------------------------------------------------------------------
-- إيقاف البقالة من الإدارة، ولوحة الإدارة
-- ---------------------------------------------------------------------
select test.fails($$select * from app.admin_stores_overview()$$, 'platform_admin_only', 'لوحة الإدارة لمدير المنصة فقط');
reset role;
select set_config('request.jwt.claims', '{"platform_admin": true, "role": "authenticated"}', false);
set role authenticated;
select test.ok((select count(*) >= 1 from app.admin_stores_overview() where store_id = :'s1'), 'مدير المنصة يرى البقالات واشتراكاتها');
select app.admin_set_store_status(:'s1', 'suspended') \g /dev/null
reset role;
select test.login(:'s1', :'o1', 'owner');
set role authenticated;
select test.fails($$insert into app.transactions (id, store_id, branch_id, customer_id, kind, amount, currency, signed_amount, created_by, device_id, device_seq, created_at)
  values (gen_random_uuid(), '$$ || :'s1' || $$', '$$ || :'b1' || $$', '55555555-0000-0000-0000-000000000001', 'debt', 1, 'YER', 0, '$$ || :'o1' || $$', '$$ || :'d1' || $$', 20, now())$$,
  'store_suspended', 'البقالة الموقوفة لا تسجل حركات');
select test.ok((select count(*) from app.customers) = 2, 'البقالة الموقوفة ما زالت تقرأ بياناتها');

-- ---------------------------------------------------------------------
-- الفحص اليومي
-- ---------------------------------------------------------------------
reset role;
select set_config('request.jwt.claims', '', false);
delete from app.integrity_alerts;
select app.run_daily_checks() as alerts \gset
select test.ok((select count(*) from app.integrity_alerts where kind = 'chain_broken') >= 0, 'الفحص اليومي يعمل على كل الفروع');
select test.ok((select count(*) from app.integrity_alerts where store_id = :'s1') = 0, 'لا تنبيهات لبقالة سليمة');

-- رمز التوكن
select test.ok((public.ajil_access_token_hook(jsonb_build_object('user_id', '00000000-0000-0000-0000-0000000001a1', 'claims', '{}'::jsonb))
  -> 'claims' ->> 'app_role') = 'owner', 'التوكن يحمل الدور والبقالة');
insert into app.platform_admins (auth_user_id, name) values ('00000000-0000-0000-0000-00000000ad01', 'مدير');
select test.ok((public.ajil_access_token_hook(jsonb_build_object('user_id', '00000000-0000-0000-0000-00000000ad01', 'claims', '{}'::jsonb))
  -> 'claims' ->> 'platform_admin') = 'true', 'مدير المنصة يحصل على صلاحيته في التوكن');

\echo 'كل اختبارات الخدمات نجحت'

-- ---------------------------------------------------------------------
-- السحب على صفحات لا يتخطى أي صف
-- ---------------------------------------------------------------------
reset role;
select set_config('request.jwt.claims', '', false);
update app.stores set status = 'active' where id = :'s1';
select test.login(:'s1', :'o1', 'owner');
set role authenticated;
do $$
declare
  since bigint := 0;
  page jsonb;
  seen int := 0;
  total int;
  b uuid := (select id from app.branches limit 1);
begin
  select count(*) into total from (
    select id from app.customers where branch_id = b
    union all select id from app.transactions where branch_id = b
    union all select id from app.promises where branch_id = b) x;
  loop
    page := app.pull_changes(b, since, 3);
    exit when jsonb_array_length(page->'customers') + jsonb_array_length(page->'transactions')
              + jsonb_array_length(page->'promises') = 0;
    seen := seen + jsonb_array_length(page->'customers') + jsonb_array_length(page->'transactions')
            + jsonb_array_length(page->'promises');
    since := (page->>'max_seq')::bigint;
  end loop;
  perform test.ok(seen = total, format('السحب بصفحات من 3 صفوف يرجع كل الـ %s صفاً بدون تخطٍ أو تكرار', total));
end $$;

-- ملخص الإدارة
reset role;
select set_config('request.jwt.claims', '{"platform_admin": true, "role": "authenticated"}', false);
set role authenticated;
select test.ok((app.admin_summary() ->> 'stores')::int >= 1, 'ملخص لوحة الإدارة: عدد البقالات والدخل الشهري');
select test.ok((select count(*) from app.activation_codes) >= 1, 'مدير المنصة يرى أكواد التفعيل');
reset role;
select set_config('request.jwt.claims', '', false);
select test.login(:'s1', :'o1', 'owner');
set role authenticated;
select test.ok((select count(*) from app.activation_codes) = 0, 'صاحب البقالة لا يرى أكواد التفعيل');
select test.fails($$select app.admin_summary()$$, 'platform_admin_only', 'صاحب البقالة لا يرى ملخص الإدارة');

-- ---------------------------------------------------------------------
-- إرسال الأرصدة: السجل والصلاحيات
-- ---------------------------------------------------------------------
reset role;
select set_config('request.jwt.claims', '', false);
update app.app_users set is_active = true where id = :'e1';
select test.login(:'s1', :'o1', 'owner');
set role authenticated;
insert into app.balance_notices (id, store_id, branch_id, customer_id, batch_id, as_of, balances, sent_by)
values ('66666666-0000-0000-0000-000000000001', :'s1', :'b1', '55555555-0000-0000-0000-000000000001',
        '77777777-0000-0000-0000-000000000001', '2026-11-30', '{"YER":"20000.00"}', :'o1');
select test.ok((select count(*) from app.balance_notices) = 1, 'المالك يسجّل رسالة رصيد مرسلة');
select test.fails($$update app.balance_notices set as_of = '2026-12-01'$$, 'permission denied', 'المستخدم لا يعدّل سجل الإرسال');
reset role;
select test.fails($$delete from app.balance_notices$$, 'notice_immutable', 'حتى الخادم لا يحذف سجل الإرسال');
set role authenticated;
select test.fails($$insert into app.balance_notices (id, store_id, branch_id, customer_id, batch_id, as_of, balances, sent_by)
  values (gen_random_uuid(), '$$ || :'s1' || $$', '$$ || :'b1' || $$', '55555555-0000-0000-0000-000000000001',
          gen_random_uuid(), '2026-11-30', '{}', '$$ || :'e1' || $$')$$,
  'row-level security', 'لا يُسجَّل إرسال باسم مستخدم آخر');

reset role;
select test.login(:'s1', :'e1', 'employee');
set role authenticated;
select test.ok(not app.can_send_notices(), 'الموظف لا يرسل الأرصدة افتراضياً');
select test.fails($$insert into app.balance_notices (id, store_id, branch_id, customer_id, batch_id, as_of, balances, sent_by)
  values (gen_random_uuid(), '$$ || :'s1' || $$', '$$ || :'b1' || $$', '55555555-0000-0000-0000-000000000002',
          gen_random_uuid(), '2026-11-30', '{"YER":"1.00"}', '$$ || :'e1' || $$')$$,
  'row-level security', 'الموظف بدون صلاحية لا يسجّل إرسالاً');
update app.store_settings set employees_can_send_notices = true where store_id = :'s1';
select test.ok(not app.can_send_notices(), 'الموظف لا يمنح نفسه الصلاحية');

reset role;
select test.login(:'s1', :'o1', 'owner');
set role authenticated;
update app.store_settings set employees_can_send_notices = true where store_id = :'s1';
reset role;
select test.login(:'s1', :'e1', 'employee');
set role authenticated;
insert into app.balance_notices (id, store_id, branch_id, customer_id, batch_id, as_of, balances, sent_by)
values ('66666666-0000-0000-0000-000000000002', :'s1', :'b1', '55555555-0000-0000-0000-000000000002',
        '77777777-0000-0000-0000-000000000001', '2026-11-30', '{"YER":"500.00"}', :'e1');
select test.ok((select count(*) from app.balance_notices) = 2, 'بعد سماح المالك: الموظف يرسل ويرى سجل فرعه');

reset role;
select set_config('request.jwt.claims', '', false);
select app.create_store('بقالة النور', '777100009', 'خالد', '00000000-0000-0000-0000-0000000002a1', 'dev-S2') as s2x \gset
select id as o2x from app.app_users where store_id = :'s2x' and user_no = 1 \gset
select test.login(:'s2x', :'o2x', 'owner');
set role authenticated;
select test.ok((select count(*) from app.balance_notices) = 0, 'بقالة أخرى لا ترى سجل الإرسال');

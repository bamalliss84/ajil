-- =====================================================================
-- اختبارات رابط كشف الحساب العام (migration 13)
-- =====================================================================
\set QUIET on
\pset tuples_only on
\pset format unaligned
\ir _helpers.sql

reset role;
select set_config('request.jwt.claims', '', false);

-- ---------------------------------------------------------------------
-- التجهيز: بقالتان، الأولى بفرعين وموظف في الفرع الثاني
-- ---------------------------------------------------------------------
select app.create_store('بقالة الفجر', '777400001', 'ماجد', '00000000-0000-0000-0000-0000000004a1', 'dev-L1') as s1 \gset
select app.create_store('بقالة الغد',  '777400002', 'رامي', '00000000-0000-0000-0000-0000000004b1', 'dev-L2') as s2 \gset
select id as o1 from app.app_users where store_id = :'s1' and user_no = 1 \gset
select id as o2 from app.app_users where store_id = :'s2' and user_no = 1 \gset
select id as b1 from app.branches where store_id = :'s1' \gset

select test.login(:'s1', :'o1', 'owner');
set role authenticated;
select (app.register_device('dev-L1')).id as d1 \gset
select (app.add_branch('فرع ثانٍ')).id as b1b \gset
select (app.add_employee('وليد', '00000000-0000-0000-0000-0000000004e1', array[:'b1b']::uuid[])).id as e1 \gset
insert into app.customers (id, store_id, branch_id, name, phone, notes, default_currency, credit_limit, credit_limit_currency)
values ('aaaaaaaa-0000-0000-0000-000000000001', :'s1', :'b1', 'سامي', '777999111', 'ملاحظة سرية', 'YER', 50000, 'YER'),
       ('aaaaaaaa-0000-0000-0000-000000000002', :'s1', :'b1', 'مؤرشف لاحقاً', null, null, 'YER', null, null);
insert into app.transactions (id, store_id, branch_id, customer_id, kind, amount, currency, signed_amount, description, created_by, device_id, device_seq, created_at)
values ('bbbbbbbb-0000-0000-0000-000000000001', :'s1', :'b1', 'aaaaaaaa-0000-0000-0000-000000000001', 'debt', 10000, 'YER', 0, 'أرز وسكر', :'o1', :'d1', 1, now() - interval '2 days'),
       ('bbbbbbbb-0000-0000-0000-000000000002', :'s1', :'b1', 'aaaaaaaa-0000-0000-0000-000000000001', 'debt', 999, 'YER', 0, 'خطأ', :'o1', :'d1', 2, now() - interval '1 day'),
       ('bbbbbbbb-0000-0000-0000-000000000003', :'s1', :'b1', 'aaaaaaaa-0000-0000-0000-000000000001', 'payment', 4000, 'YER', 0, null, :'o1', :'d1', 3, now());
insert into app.transactions (id, store_id, branch_id, customer_id, kind, amount, currency, signed_amount, voided_id, void_reason, created_by, device_id, device_seq, created_at)
values ('bbbbbbbb-0000-0000-0000-000000000004', :'s1', :'b1', 'aaaaaaaa-0000-0000-0000-000000000001', 'void', 1, 'YER', 0,
        'bbbbbbbb-0000-0000-0000-000000000002', 'مبلغ خاطئ', :'o1', :'d1', 4, now());
insert into app.promises (id, store_id, branch_id, customer_id, promised_date, amount, currency, note)
values ('cccccccc-0000-0000-0000-000000000001', :'s1', :'b1', 'aaaaaaaa-0000-0000-0000-000000000001', current_date + 3, 6000, 'YER', 'وعد سري');

-- ---------------------------------------------------------------------
-- إنشاء الرابط
-- ---------------------------------------------------------------------
select app.statement_link('aaaaaaaa-0000-0000-0000-000000000001') as tok1 \gset
select test.ok(:'tok1' ~ '^[A-Za-z0-9_-]{22}$', 'الـ token بترميز base64url بدون padding (128 بت = 22 حرفاً)');
select test.ok(app.statement_link('aaaaaaaa-0000-0000-0000-000000000001') = :'tok1', 'الطلب الثاني يرجع نفس الرابط');
select test.fails($$insert into app.statement_links (customer_id, store_id, branch_id, token)
  values ('aaaaaaaa-0000-0000-0000-000000000002', '$$ || :'s1' || $$', '$$ || :'b1' || $$', 'x')$$,
  'permission denied', 'المستخدم لا يُدخل رابطاً مباشرة');
select test.fails($$update app.statement_links set token = 'x'$$, 'permission denied', 'المستخدم لا يعدّل الرابط مباشرة');
select test.ok((select count(*) from app.statement_links) = 1, 'المالك يقرأ روابط فرعه');
select app.statement_link('aaaaaaaa-0000-0000-0000-000000000002') as tok_arch \gset

-- ---------------------------------------------------------------------
-- الكشف العام بدور anon
-- ---------------------------------------------------------------------
reset role;
select set_config('request.jwt.claims', '{"role": "anon"}', false);
set role anon;
select app.public_statement(:'tok1')::text as st1 \gset
select test.fails('select * from app.statement_links', 'permission denied', 'anon لا يقرأ جدول الروابط مباشرة');
select test.fails('select * from app.customers', 'permission denied', 'anon لا يقرأ جداول البقالة');
select test.fails($$select app.statement_link('aaaaaaaa-0000-0000-0000-000000000001')$$, 'permission denied',
  'anon لا ينشئ روابط');
select (app.public_statement('AAAAAAAAAAAAAAAAAAAAAA') is null)::text as bad1,
       (app.public_statement('not a token') is null)::text as bad2,
       (app.public_statement(null) is null)::text as bad3 \gset
reset role;

select test.ok(:'st1'::jsonb ->> 'customer_name' = 'سامي' and :'st1'::jsonb ->> 'store_name' = 'بقالة الفجر'
               and :'st1'::jsonb ? 'branch_name' and :'st1'::jsonb ? 'generated_at',
  'الكشف العام يرجع اسم البقالة والفرع والزبون ووقت الاستعلام');
select test.ok((:'st1'::jsonb -> 'balances' -> 0 ->> 'balance')::numeric = 6000
               and :'st1'::jsonb -> 'balances' -> 0 ->> 'currency' = 'YER',
  'الكشف العام يرجع الرصيد لكل عملة (10,000 − 4,000 = 6,000)');
select test.ok((:'st1'::jsonb -> 'balances' -> 0 ->> 'total_debit')::numeric = 10000
               and (:'st1'::jsonb -> 'balances' -> 0 ->> 'total_credit')::numeric = 4000,
  'إجمالي الديون والمسدد بدون الحركة الملغاة وقيدها');
select test.ok(jsonb_array_length(:'st1'::jsonb -> 'transactions') = 2
               and not (:'st1'::jsonb -> 'transactions')::text ~ '"void"'
               and not (:'st1'::jsonb -> 'transactions')::text ~ '999',
  'الحركات بدون الملغاة وبدون قيود الإلغاء');
select test.ok(:'st1'::jsonb -> 'transactions' -> 0 ->> 'kind' = 'payment'
               and :'st1'::jsonb -> 'transactions' -> 1 ->> 'description' = 'أرز وسكر',
  'الحركات مرتبة من الأحدث وفيها النوع والوصف');
select test.ok(jsonb_array_length(:'st1'::jsonb -> 'promises') = 1
               and (:'st1'::jsonb -> 'promises' -> 0 ->> 'amount')::numeric = 6000,
  'الكشف يرجع الوعود المفتوحة');
select test.ok(:'st1' !~ '777999111' and :'st1' !~ 'phone' and :'st1' !~ 'notes' and :'st1' !~ 'ملاحظة سرية'
               and :'st1' !~ 'credit_limit' and :'st1' !~ '50000' and :'st1' !~ 'وعد سري',
  'الرد لا يحتوي الجوال ولا الملاحظات ولا سقف الدين');
select test.ok(:'st1' !~ :'s1' and :'st1' !~ :'b1' and :'st1' !~ 'aaaaaaaa-' and :'st1' !~ 'bbbbbbbb-'
               and :'st1' !~ :'o1' and :'st1' !~ '"id"',
  'الرد لا يحتوي أي معرّفات');
select test.ok(:'bad1'::boolean and :'bad2'::boolean and :'bad3'::boolean, 'token غير موجود أو بصيغة خاطئة يرجع null');
select test.ok((select view_count = 1 and last_viewed_at is not null from app.statement_links
                where customer_id = 'aaaaaaaa-0000-0000-0000-000000000001'), 'فتح الكشف يحدّث عدد المشاهدات ووقت آخرها');
select test.ok(not has_function_privilege('anon', 'app.statement_link(uuid,boolean)', 'execute')
           and not has_function_privilege('authenticated', 'app.public_statement(text)', 'execute')
           and has_function_privilege('anon', 'app.public_statement(text)', 'execute')
           and not has_function_privilege('authenticated', 'app.new_statement_token()', 'execute'),
  'public_statement لـ anon فقط، و statement_link للمستخدم المسجل فقط');

-- زبون مؤرشف وبقالة موقوفة
select test.login(:'s1', :'o1', 'owner');
set role authenticated;
update app.customers set status = 'archived' where id = 'aaaaaaaa-0000-0000-0000-000000000002';
reset role;
select test.ok(app.public_statement(:'tok_arch') is null, 'رابط زبون مؤرشف يرجع null');
update app.stores set status = 'suspended' where id = :'s1';
select test.ok(app.public_statement(:'tok1') is null, 'رابط بقالة موقوفة يرجع null');
update app.stores set status = 'active' where id = :'s1';

-- ---------------------------------------------------------------------
-- العزل والصلاحيات
-- ---------------------------------------------------------------------
select test.login(:'s2', :'o2', 'owner');
set role authenticated;
select test.fails($$select app.statement_link('aaaaaaaa-0000-0000-0000-000000000001')$$, 'customer_not_found',
  'بقالة B لا تنشئ رابطاً لزبون A');
select test.fails($$select app.revoke_statement_link('aaaaaaaa-0000-0000-0000-000000000001')$$, 'customer_not_found',
  'بقالة B لا تلغي رابط زبون A');
select test.ok((select count(*) from app.statement_links) = 0, 'بقالة B لا ترى روابط A');

reset role;
select test.login(:'s1', :'e1', 'employee');
set role authenticated;
select test.fails($$select app.statement_link('aaaaaaaa-0000-0000-0000-000000000001')$$, 'customer_not_found',
  'موظف بدون الفرع لا ينشئ رابطاً');
select test.ok((select count(*) from app.statement_links) = 0, 'موظف بدون الفرع لا يرى روابطه');
reset role;
insert into app.user_branches (user_id, branch_id) values (:'e1', :'b1');
select test.login(:'s1', :'e1', 'employee');
set role authenticated;
select test.ok(app.statement_link('aaaaaaaa-0000-0000-0000-000000000001') = :'tok1', 'الموظف في الفرع يحصل على الرابط الحالي');
select test.fails($$select app.statement_link('aaaaaaaa-0000-0000-0000-000000000001', true)$$, 'statement_link_forbidden',
  'الموظف لا يجدد الرابط افتراضياً');
reset role;
update app.store_settings set employees_can_send_notices = true where store_id = :'s1';
select test.login(:'s1', :'e1', 'employee');
set role authenticated;
select app.statement_link('aaaaaaaa-0000-0000-0000-000000000001', true) as tok_emp \gset
select test.ok(:'tok_emp' <> :'tok1', 'الموظف يجدد الرابط إن سمح المالك بإرسال الأرصدة');
reset role;
update app.store_settings set employees_can_send_notices = false where store_id = :'s1';

-- ---------------------------------------------------------------------
-- التجديد والإلغاء
-- ---------------------------------------------------------------------
select test.login(:'s1', :'o1', 'owner');
set role authenticated;
select app.statement_link('aaaaaaaa-0000-0000-0000-000000000001', true) as tok2 \gset
reset role;
select test.ok(:'tok2' <> :'tok_emp' and app.public_statement(:'tok_emp') is null and app.public_statement(:'tok1') is null
               and app.public_statement(:'tok2') is not null,
  'التجديد يُبطل الرابط القديم والجديد يعمل');
select test.login(:'s1', :'o1', 'owner');
set role authenticated;
select app.revoke_statement_link('aaaaaaaa-0000-0000-0000-000000000001') \g /dev/null
reset role;
select test.ok(app.public_statement(:'tok2') is null, 'الرابط الملغى يرجع null');
select test.login(:'s1', :'o1', 'owner');
set role authenticated;
select app.statement_link('aaaaaaaa-0000-0000-0000-000000000001') as tok3 \gset
reset role;
select test.ok(:'tok3' <> :'tok2' and app.public_statement(:'tok3') is not null, 'بعد الإلغاء يُنشأ رابط جديد عند الطلب');
select test.login(:'s1', :'o1', 'owner');
set role authenticated;
select test.fails($$select app.statement_link('aaaaaaaa-0000-0000-0000-000000000002', true)$$, 'customer_archived',
  'لا يُنشأ رابط جديد لزبون مؤرشف');
reset role;

\echo 'كل اختبارات رابط الكشف نجحت'

-- =====================================================================
-- بيانات تجريبية كثيرة لبقالة واحدة (للتجربة اليدوية فقط — ليست migration)
-- الاستخدام (داخل حاوية القاعدة):
--   docker exec -i supabase_db_ajil psql -U postgres -v ON_ERROR_STOP=1 \
--     -v phone=777555123 < supabase/seed_demo.sql
-- يضيف: موظفاً تجريبياً (بلا دخول)، ~70 زبوناً، حركات من سبتمبر 2025 حتى الآن
-- (ديون، سداد، مرتجع، خصم، افتتاحي، سداد بعملة أخرى، إلغاءات)، ووعود سداد.
-- كل الإدخال عبر الـ triggers العادية (الإشارة، الرصيد، سلسلة البصمات).
-- =====================================================================
\set ON_ERROR_STOP 1
select set_config('demo.phone', :'phone', false);

do $$
declare
  v_store  uuid;
  v_branch uuid;
  v_owner  uuid;
  v_emp    uuid;
  v_start  date := date '2025-09-01';
  v_today  date := (now() at time zone 'Asia/Aden')::date;
  d        date;
  i        int;
  n        int;
  k        int;
  c        record;
  t        record;
  v_cust   uuid;
  v_cur    text;
  v_amt    numeric;
  v_at     timestamptz;
  v_by     uuid;
  v_bal    numeric;
  v_kind   text;
  v_growth numeric;
  v_hour   int;
  first_names text[] := array['عبدالله','محمد','أحمد','سالم','خالد','سعيد','عمر','علي','حسن','فهد',
    'ناصر','عوض','صالح','يسلم','مبارك','فاطمة','عائشة','مريم','خديجة','نور','أم علي','أم محمد','أبو سالم','أبو خالد'];
  last_names text[] := array['باوزير','العمودي','بن سلم','بامطرف','باعباد','الكثيري','بن طالب','باحاج',
    'الجابري','بافقيه','باشراحيل','بن مخاشن','التميمي','باسويد','العطاس','بلفقيه','الحضرمي','بن دغر'];
  debt_desc text[] := array['مواد غذائية','رز وسكر','خضار وفواكه','حليب أطفال','أسطوانة غاز','منظفات',
    'زيت وطحين','مشروبات','لحوم مجمدة','بيض وجبن','خبز','حفاضات','معلبات','قرطاسية مدرسية', null, null];
  pay_desc text[] := array['نقداً','تحويل','سداد جزئي','سداد الشهر', null, null];
begin
  select id into v_store from app.stores where owner_phone = current_setting('demo.phone');
  if v_store is null then raise exception 'store_not_found: لا توجد بقالة بهذا الرقم'; end if;
  select id into v_branch from app.branches where store_id = v_store order by created_at limit 1;
  select id into v_owner from app.app_users where store_id = v_store and role = 'owner';

  perform setseed(0.42);

  -- موظف تجريبي (بدون حساب دخول)
  select id into v_emp from app.app_users where store_id = v_store and display_name = 'خالد';
  if v_emp is null then
    insert into app.app_users (store_id, user_no, display_name, role)
    values (v_store, (select max(user_no) + 1 from app.app_users where store_id = v_store), 'خالد', 'employee')
    returning id into v_emp;
    insert into app.user_branches (user_id, branch_id) values (v_emp, v_branch);
  end if;

  -- الزبائن: ملف لكل زبون (موثوقية السداد، العملة، حجم المشتريات)
  create temp table demo_c (
    id uuid primary key, cur text, reliab numeric, size numeric, joined date
  ) on commit drop;

  for i in 1..70 loop
    v_cust := gen_random_uuid();
    v_cur  := case when i % 9 = 0 then 'SAR' else 'YER' end;
    -- 45 زبوناً من البداية، والباقي ينضمون تدريجياً
    d := case when i <= 45 then v_start + (random() * 20)::int
              else v_start + (random() * (v_today - v_start - 5))::int end;
    insert into app.customers (id, store_id, branch_id, name, phone, address, default_currency,
                               credit_limit, credit_limit_currency, created_by, created_at)
    values (v_cust, v_store, v_branch,
            first_names[1 + (random() * (array_length(first_names,1) - 1))::int] || ' ' ||
            last_names[1 + (random() * (array_length(last_names,1) - 1))::int],
            '77' || lpad((random() * 9999999)::bigint::text, 7, '0'),
            (array['فوة','الديس','الشرج','المكلا القديمة','ابن سيناء', null])[1 + (random() * 5)::int],
            v_cur,
            case when i % 4 = 0 then (case when v_cur = 'SAR' then 1500 else 150000 end) end,
            case when i % 4 = 0 then v_cur end,
            v_owner, (d + time '09:00') at time zone 'Asia/Aden');
    insert into demo_c values (v_cust, v_cur,
      case when i % 11 = 0 then 0.05            -- لا يسدد تقريباً (يظهر في «بلا سداد» وأعمار الديون)
           when i % 5 = 0 then 0.35 + random() * 0.2
           else 0.7 + random() * 0.3 end,
      0.5 + random() * 1.5, d);

    -- رصيد افتتاحي لربع الزبائن (من الدفتر الورقي)
    if i % 4 = 1 then
      insert into app.transactions (id, store_id, branch_id, customer_id, kind, amount, currency,
                                    signed_amount, description, created_by, created_at)
      values (gen_random_uuid(), v_store, v_branch, v_cust, 'opening',
              case when v_cur = 'SAR' then round((100 + random() * 900)::numeric, 0)
                   else round((5000 + random() * 60000)::numeric / 500) * 500 end,
              v_cur, 0, 'رصيد من الدفتر الورقي', v_owner,
              (d + time '09:05') at time zone 'Asia/Aden');
    end if;
  end loop;

  -- الحركات اليومية
  d := v_start;
  while d <= v_today loop
    v_growth := 1 + (d - v_start)::numeric / 450;          -- نمو تدريجي في النشاط
    n := greatest(1, round((4 + random() * 7) * v_growth
                   * case when extract(isodow from d) = 5 then 0.5 else 1 end)::int);

    -- ديون
    for k in 1..n loop
      select * into c from demo_c where joined <= d order by random() limit 1;
      v_hour := (array[7,8,9,10,11,12,13,16,17,18,19,19,20,20,20,21,21,22])[1 + (random() * 17)::int];
      v_at := (d + make_time(v_hour, (random() * 59)::int, 0)) at time zone 'Asia/Aden';
      exit when v_at > now();
      v_by := case when d >= date '2026-03-01' and random() < 0.35 then v_emp else v_owner end;
      v_amt := case when c.cur = 'SAR' then round((10 + random() * 140 * c.size)::numeric, 0)
                    else round(((500 + random() * 9500) * c.size)::numeric / 50) * 50 end;
      insert into app.transactions (id, store_id, branch_id, customer_id, kind, amount, currency,
                                    signed_amount, description, created_by, created_at)
      values (gen_random_uuid(), v_store, v_branch, c.id, 'debt', v_amt, c.cur, 0,
              debt_desc[1 + (random() * (array_length(debt_desc,1) - 1))::int], v_by, v_at);
    end loop;

    -- سداد: زبائن لديهم رصيد، باحتمال موثوقيتهم
    for k in 1..greatest(1, round(n * (0.35 + random() * 0.3))::int) loop
      select dc.*, b.balance into c
        from demo_c dc join app.customer_balances b on b.customer_id = dc.id and b.currency = dc.cur
       where dc.joined <= d and b.balance > 0 and random() < dc.reliab
       order by random() limit 1;
      continue when c.id is null;
      v_hour := (array[8,9,10,11,12,17,18,19,20,20,21])[1 + (random() * 10)::int];
      v_at := (d + make_time(v_hour, (random() * 59)::int, 0)) at time zone 'Asia/Aden';
      continue when v_at > now();
      v_by := case when d >= date '2026-03-01' and random() < 0.3 then v_emp else v_owner end;
      v_amt := least(c.balance, case when random() < 0.3 then c.balance
               else greatest(case when c.cur = 'SAR' then 10 else 500 end,
                    round(c.balance * (0.2 + random() * 0.6) / case when c.cur = 'SAR' then 1 else 500 end)
                    * case when c.cur = 'SAR' then 1 else 500 end) end);
      continue when v_amt <= 0;
      if c.cur = 'SAR' and random() < 0.25 then
        -- زبون عليه دين بالريال السعودي يسدد بالريال اليمني
        insert into app.transactions (id, store_id, branch_id, customer_id, kind, amount, currency,
                                      signed_amount, fx_paid_amount, fx_paid_currency, fx_rate,
                                      description, created_by, created_at)
        values (gen_random_uuid(), v_store, v_branch, c.id, 'payment_fx', v_amt, 'SAR', 0,
                v_amt * 425, 'YER', 425, 'سداد بالريال اليمني', v_by, v_at);
      else
        insert into app.transactions (id, store_id, branch_id, customer_id, kind, amount, currency,
                                      signed_amount, description, created_by, created_at)
        values (gen_random_uuid(), v_store, v_branch, c.id, 'payment', v_amt, c.cur, 0,
                pay_desc[1 + (random() * (array_length(pay_desc,1) - 1))::int], v_by, v_at);
      end if;
    end loop;

    -- مرتجع / خصم أحياناً
    if random() < 0.18 then
      select dc.*, b.balance into c
        from demo_c dc join app.customer_balances b on b.customer_id = dc.id and b.currency = dc.cur
       where dc.joined <= d and b.balance > (case when dc.cur = 'SAR' then 20 else 2000 end)
       order by random() limit 1;
      v_at := (d + make_time(19, (random() * 59)::int, 0)) at time zone 'Asia/Aden';
      if c.id is not null and v_at <= now() then
        v_kind := case when random() < 0.6 then 'return' else 'discount' end;
        insert into app.transactions (id, store_id, branch_id, customer_id, kind, amount, currency,
                                      signed_amount, description, created_by, created_at)
        values (gen_random_uuid(), v_store, v_branch, c.id, v_kind,
                case when c.cur = 'SAR' then 5 + (random() * 15)::int
                     else round((300 + random() * 1700)::numeric / 50) * 50 end,
                c.cur, 0, case when v_kind = 'return' then 'إرجاع بضاعة' else 'خصم تاجر' end,
                v_owner, v_at);
      end if;
    end if;

    -- إلغاء دين مسجّل بالخطأ (قيد عكسي) أحياناً
    if random() < 0.06 then
      select tx.* into t from app.transactions tx
       where tx.branch_id = v_branch and tx.kind = 'debt'
         and (tx.created_at at time zone 'Asia/Aden')::date = d
         and not exists (select 1 from app.transactions x where x.voided_id = tx.id)
       order by random() limit 1;
      if t.id is not null and t.created_at + interval '10 minutes' <= now() then
        insert into app.transactions (id, store_id, branch_id, customer_id, kind, amount, currency,
                                      signed_amount, voided_id, void_reason, created_by, created_at)
        values (gen_random_uuid(), v_store, v_branch, t.customer_id, 'void', t.amount, t.currency, 0,
                t.id, (array['مبلغ خاطئ','سُجّل على زبون آخر','مكرر'])[1 + (random() * 2)::int],
                v_owner, t.created_at + interval '10 minutes');
      end if;
    end if;

    d := d + 1;
  end loop;

  -- وعود السداد: موفى بها، متأخرة، قادمة
  for c in select dc.*, b.balance from demo_c dc
             join app.customer_balances b on b.customer_id = dc.id and b.currency = dc.cur
            where b.balance > 0 order by random() limit 30 loop
    d := v_today + (-20 + (random() * 34)::int);
    insert into app.promises (id, store_id, branch_id, customer_id, promised_date, amount, currency,
                              note, remind_day_before, status, created_by, created_at)
    values (gen_random_uuid(), v_store, v_branch, c.id, d,
            round(c.balance * 0.5 / case when c.cur = 'SAR' then 1 else 500 end)
              * case when c.cur = 'SAR' then 1 else 500 end + case when c.cur = 'SAR' then 1 else 500 end,
            c.cur, (array['بعد الراتب','آخر الشهر','وعد هاتفي', null])[1 + (random() * 3)::int],
            random() < 0.5,
            case when d < v_today and random() < 0.6 then 'kept' else 'open' end,
            v_owner, now() - interval '25 days');
  end loop;

  raise notice 'demo: customers=%, transactions=%, promises=%',
    (select count(*) from app.customers where branch_id = v_branch),
    (select count(*) from app.transactions where branch_id = v_branch),
    (select count(*) from app.promises where branch_id = v_branch);
end $$;

-- =====================================================================
-- دعم الخدمات: رموز OTP، توقيع الأجهزة وبوابة المزامنة، أكواد التفعيل،
-- الفحص اليومي، قائمة التحصيل، الوعود المنفّذة، إعدادات المالك، لوحة الإدارة
-- =====================================================================

-- ---------------------------------------------------------------------
-- إعدادات المنصة (قيم داخلية لا يقرؤها المستخدمون)
-- ---------------------------------------------------------------------
create table app.platform_config (
  key   text primary key,
  value text not null
);
alter table app.platform_config enable row level security;   -- بدون سياسات = لا أحد عبر API
insert into app.platform_config (key, value) values
  ('require_gateway', 'false'),        -- في الإنتاج: true (الحركات تمر من sync-push فقط)
  ('gateway_secret_sha256', '')        -- sha256 للسر المشترك مع Edge Function
on conflict do nothing;

create or replace function app.config(p_key text) returns text
language sql stable security definer set search_path = app, public as $$
  select value from app.platform_config where key = p_key
$$;
revoke execute on function app.config(text) from public;

-- هل الطلب قادم من بوابة المزامنة (Edge Function)؟
create or replace function app.via_gateway() returns boolean
language plpgsql stable security definer set search_path = app, public as $$
declare
  hdr text;
begin
  if coalesce(app.config('require_gateway'), 'false') <> 'true' then
    return true;
  end if;
  hdr := nullif(current_setting('request.headers', true), '')::jsonb ->> 'x-ajil-gateway';
  return hdr is not null
     and encode(sha256(convert_to(hdr, 'UTF8')), 'hex') = app.config('gateway_secret_sha256');
end $$;

-- الحركات: إضافة شرط البوابة إلى سياسة الإدخال
drop policy tx_insert on app.transactions;
create policy tx_insert on app.transactions for insert to authenticated
  with check (store_id = app.store_id() and app.has_branch(branch_id)
              and created_by = app.app_user_id()
              and app.device_ok(device_id)
              and app.via_gateway());

-- ---------------------------------------------------------------------
-- رموز التحقق OTP (تُخزَّن مُجزّأة، لا نصاً)
-- ---------------------------------------------------------------------
create table app.otp_codes (
  id          uuid primary key default gen_random_uuid(),
  phone       text not null,
  purpose     text not null check (purpose in ('register','reset_owner')),
  code_hash   text not null,
  attempts    int not null default 0,
  expires_at  timestamptz not null,
  consumed_at timestamptz,
  created_at  timestamptz not null default now()
);
create index on app.otp_codes (phone, purpose, created_at desc);
alter table app.otp_codes enable row level security;

-- إصدار رمز: 6 أرقام، صلاحية 5 دقائق، 3 رموز كل 10 دقائق و10 في اليوم
create or replace function app.otp_issue(p_phone text, p_purpose text) returns text
language plpgsql security definer set search_path = app, public as $$
declare
  code text;
  rid  uuid := gen_random_uuid();
begin
  if p_purpose = 'register' and exists (select 1 from app.stores where owner_phone = p_phone) then
    raise exception 'phone_taken: هذا الرقم مسجل لبقالة — استخدم الدخول أو استعادة كلمة المرور';
  end if;
  if p_purpose = 'reset_owner' and not exists (select 1 from app.stores where owner_phone = p_phone) then
    raise exception 'phone_unknown: لا توجد بقالة بهذا الرقم';
  end if;
  if (select count(*) from app.otp_codes where phone = p_phone and created_at > now() - interval '10 minutes') >= 3 then
    raise exception 'otp_rate_limited: طلبت رموزاً كثيرة — انتظر 10 دقائق';
  end if;
  if (select count(*) from app.otp_codes where phone = p_phone and created_at > now() - interval '1 day') >= 10 then
    raise exception 'otp_daily_limit: تجاوزت الحد اليومي للرموز';
  end if;
  code := lpad((floor(random() * 1000000))::int::text, 6, '0');
  insert into app.otp_codes (id, phone, purpose, code_hash, expires_at)
  values (rid, p_phone, p_purpose,
          encode(sha256(convert_to(rid::text || ':' || code, 'UTF8')), 'hex'),
          now() + interval '5 minutes');
  return code;
end $$;

-- التحقق: 5 محاولات للرمز، ويُستهلك مرة واحدة
create or replace function app.otp_verify(p_phone text, p_purpose text, p_code text) returns boolean
language plpgsql security definer set search_path = app, public as $$
declare
  r app.otp_codes;
begin
  select * into r from app.otp_codes
   where phone = p_phone and purpose = p_purpose and consumed_at is null
   order by created_at desc limit 1
   for update;
  if r.id is null or r.expires_at < now() then
    raise exception 'otp_expired: الرمز منتهٍ — اطلب رمزاً جديداً';
  end if;
  if r.attempts >= 5 then
    raise exception 'otp_locked: محاولات كثيرة — اطلب رمزاً جديداً';
  end if;
  if encode(sha256(convert_to(r.id::text || ':' || p_code, 'UTF8')), 'hex') <> r.code_hash then
    update app.otp_codes set attempts = attempts + 1 where id = r.id;
    return false;
  end if;
  update app.otp_codes set consumed_at = now() where id = r.id;
  return true;
end $$;

revoke execute on function app.otp_issue(text, text), app.otp_verify(text, text, text) from public;

-- ---------------------------------------------------------------------
-- مفاتيح الأجهزة ومنع إعادة الطلبات
-- ---------------------------------------------------------------------
alter table app.devices add column public_key text;   -- SPKI مشفر base64 (ECDSA P-256)

create table app.device_nonces (
  device_id uuid not null references app.devices(id),
  nonce     text not null,
  at        timestamptz not null default now(),
  primary key (device_id, nonce)
);
alter table app.device_nonces enable row level security;

-- تستدعيها البوابة: ترجع المفتاح العام إن كان الجهاز صالحاً وتسجل الـ nonce (مرة واحدة)
create or replace function app.gateway_device_key(p_device uuid, p_nonce text) returns text
language plpgsql security definer set search_path = app, public as $$
declare
  k text;
begin
  select public_key into k from app.devices
   where id = p_device and store_id = app.store_id() and approved and revoked_at is null;
  if k is null then raise exception 'device_invalid: الجهاز غير معتمد أو ملغى'; end if;
  insert into app.device_nonces (device_id, nonce) values (p_device, p_nonce);
  delete from app.device_nonces where device_id = p_device and at < now() - interval '1 day';
  return k;
exception when unique_violation then
  raise exception 'replay_detected: طلب مكرر';
end $$;

-- تسجيل الجهاز مع مفتاحه العام
create or replace function app.register_device_v2(p_device_key text, p_public_key text, p_label text default null)
returns app.devices
language plpgsql security definer set search_path = app, public as $$
declare d app.devices;
begin
  d := app.register_device(p_device_key, p_label);
  if d.public_key is null then
    update app.devices set public_key = p_public_key where id = d.id returning * into d;
  elsif d.public_key <> p_public_key then
    raise exception 'device_key_mismatch: مفتاح الجهاز تغيّر — ألغِ الجهاز وسجّله من جديد';
  end if;
  return d;
end $$;

-- ---------------------------------------------------------------------
-- أكواد التفعيل (تُباع كالكروت عند المندوبين)
-- ---------------------------------------------------------------------
create table app.activation_codes (
  code            text primary key,
  plan_code       text not null references app.plans(code),
  months          int not null check (months > 0),
  agent           text,                          -- المندوب
  created_at      timestamptz not null default now(),
  redeemed_store  uuid references app.stores(id),
  redeemed_at     timestamptz
);
alter table app.activation_codes enable row level security;

create or replace function app.generate_codes(p_plan text, p_months int, p_count int, p_agent text default null)
returns setof text
language plpgsql security definer set search_path = app, public as $$
declare
  i int;
  c text;
begin
  if not (app.is_platform_admin() or app.claims() ->> 'role' = 'service_role' or app.claims() = '{}'::jsonb) then
    raise exception 'platform_admin_only';
  end if;
  for i in 1..p_count loop
    -- 12 حرفاً بدون الحروف المتشابهة (0/O، 1/I)
    c := (select string_agg(substr('ABCDEFGHJKLMNPQRSTUVWXYZ23456789', 1 + floor(random() * 32)::int, 1), '')
          from generate_series(1, 12));
    insert into app.activation_codes (code, plan_code, months, agent) values (c, p_plan, p_months, p_agent);
    return next substr(c, 1, 4) || '-' || substr(c, 5, 4) || '-' || substr(c, 9, 4);
  end loop;
end $$;

create or replace function app.redeem_code(p_code text) returns app.subscriptions
language plpgsql security definer set search_path = app, public as $$
declare
  ac app.activation_codes;
  cur app.subscriptions;
  s app.subscriptions;
  clean text := upper(replace(replace(p_code, '-', ''), ' ', ''));
begin
  if app.user_role() <> 'owner' then raise exception 'owner_only: التفعيل للمالك فقط'; end if;
  select * into ac from app.activation_codes where code = clean for update;
  if ac.code is null then raise exception 'code_invalid: الكود غير صحيح'; end if;
  if ac.redeemed_at is not null then raise exception 'code_used: الكود مستخدم مسبقاً'; end if;
  cur := app.current_subscription(app.store_id());
  insert into app.subscriptions (store_id, plan_code, starts_at, expires_at, activated_by, payment_ref)
  values (app.store_id(), ac.plan_code, now(),
          greatest(now(), coalesce(cur.expires_at, now())) + make_interval(months => ac.months),
          'code:' || coalesce(ac.agent, '-'), ac.code)
  returning * into s;
  update app.activation_codes set redeemed_store = app.store_id(), redeemed_at = now() where code = clean;
  return s;
end $$;

revoke execute on function app.generate_codes(text, int, int, text) from public;
grant execute on function app.generate_codes(text, int, int, text) to authenticated;  -- يتحقق داخلياً
grant execute on function app.redeem_code(text), app.register_device_v2(text, text, text),
                          app.gateway_device_key(uuid, text) to authenticated;

-- ---------------------------------------------------------------------
-- الوعد يُعتبر منفّذاً تلقائياً عند السداد
-- ---------------------------------------------------------------------
create or replace function app.tx_mark_promises() returns trigger
language plpgsql security definer set search_path = app, public as $$
declare
  bal numeric;
begin
  if new.kind not in ('payment', 'payment_fx', 'discount', 'return') then return null; end if;
  select balance into bal from app.customer_balances
   where customer_id = new.customer_id and currency = new.currency;
  update app.promises p set status = 'kept'
   where p.customer_id = new.customer_id and p.status = 'open'
     and (coalesce(bal, 0) <= 0
          or (p.amount is not null and coalesce(p.currency, new.currency) = new.currency and new.amount >= p.amount));
  return null;
end $$;
create trigger tx_mark_promises after insert on app.transactions
  for each row execute function app.tx_mark_promises();

-- ---------------------------------------------------------------------
-- قائمة «مطلوب تحصيله اليوم» لفرع
-- ---------------------------------------------------------------------
create or replace function app.due_today(p_branch uuid, p_today date default current_date)
returns table (customer_id uuid, customer_name text, reason text, due_date date,
               amount numeric, currency text, balance numeric)
language sql stable security invoker set search_path = app, public as $$
  -- الوعود المفتوحة التي حلّ موعدها أو تأخر
  select p.customer_id, c.name,
         case when p.promised_date < p_today then 'promise_overdue' else 'promise_today' end,
         p.promised_date, p.amount, coalesce(p.currency, c.default_currency),
         coalesce(b.balance, 0)
  from app.promises p
  join app.customers c on c.id = p.customer_id
  left join app.customer_balances b on b.customer_id = p.customer_id
       and b.currency = coalesce(p.currency, c.default_currency)
  where p.branch_id = p_branch and p.status = 'open' and p.promised_date <= p_today
  union all
  -- ديون لها موعد سداد اليوم أو قبله والزبون ما زال مديناً بتلك العملة
  select t.customer_id, c.name, 'invoice_due', t.due_date, t.amount, t.currency, b.balance
  from app.transactions t
  join app.customers c on c.id = t.customer_id
  join app.customer_balances b on b.customer_id = t.customer_id and b.currency = t.currency
  where t.branch_id = p_branch and t.kind = 'debt' and t.due_date is not null
    and t.due_date <= p_today and b.balance > 0
    and not exists (select 1 from app.transactions v where v.voided_id = t.id)
  order by 4, 2
$$;
grant execute on function app.due_today(uuid, date) to authenticated;

-- ---------------------------------------------------------------------
-- إعدادات المالك: البقالة والتنبيهات
-- ---------------------------------------------------------------------
grant update (name, default_currency, enabled_currencies) on app.stores to authenticated;
create policy stores_owner_update on app.stores for update to authenticated
  using (id = app.store_id() and app.user_role() = 'owner')
  with check (id = app.store_id());

grant update (monthly_claim_enabled, monthly_claim_day, monthly_claim_time, monthly_claim_min,
              overdue_days, employee_void_hours, reminder_template) on app.store_settings to authenticated;
create policy settings_owner_update on app.store_settings for update to authenticated
  using (store_id = app.store_id() and app.user_role() = 'owner')
  with check (store_id = app.store_id());

-- المالك يوقف أو يعيد تفعيل موظف، ويغيّر فروعه
create or replace function app.set_employee(p_user uuid, p_active boolean, p_branches uuid[] default null)
returns app.app_users
language plpgsql security definer set search_path = app, public as $$
declare u app.app_users;
begin
  if app.user_role() <> 'owner' then raise exception 'owner_only'; end if;
  update app.app_users set is_active = p_active
   where id = p_user and store_id = app.store_id() and role = 'employee'
  returning * into u;
  if u.id is null then raise exception 'user_not_found'; end if;
  if p_branches is not null then
    delete from app.user_branches where user_id = u.id;
    insert into app.user_branches (user_id, branch_id)
    select u.id, b from unnest(p_branches) b
    where exists (select 1 from app.branches where id = b and store_id = app.store_id());
  end if;
  return u;
end $$;
grant execute on function app.set_employee(uuid, boolean, uuid[]) to authenticated;

-- ---------------------------------------------------------------------
-- الفحص اليومي وتنبيهات الإدارة
-- ---------------------------------------------------------------------
create table app.integrity_alerts (
  id         bigint generated always as identity primary key,
  kind       text not null,            -- chain_broken, balance_mismatch
  store_id   uuid,
  branch_id  uuid,
  details    jsonb,
  at         timestamptz not null default now(),
  resolved   boolean not null default false
);
alter table app.integrity_alerts enable row level security;
create policy alerts_admin on app.integrity_alerts for select to authenticated using (app.is_platform_admin());

create or replace function app.run_daily_checks() returns int
language plpgsql security definer set search_path = app, public as $$
declare
  b record;
  v record;
  m record;
  n int := 0;
begin
  for b in select id, store_id from app.branches loop
    select * into v from app.verify_chain(b.id);
    if not v.ok then
      insert into app.integrity_alerts (kind, store_id, branch_id, details)
      values ('chain_broken', b.store_id, b.id, jsonb_build_object('broken_at', v.broken_at));
      n := n + 1;
    end if;
  end loop;
  for m in select * from app.balance_mismatches() loop
    insert into app.integrity_alerts (kind, store_id, details)
    select 'balance_mismatch', c.store_id, to_jsonb(m) from app.customers c where c.id = m.customer_id;
    n := n + 1;
  end loop;
  return n;
end $$;
revoke execute on function app.run_daily_checks() from public;

-- جدولة يومية إن كانت pg_cron متاحة (في Supabase: فعّلها من Database → Extensions)
do $$
begin
  if exists (select 1 from pg_extension where extname = 'pg_cron') then
    perform cron.schedule('ajil-daily-checks', '0 1 * * *', 'select app.run_daily_checks()');
  end if;
end $$;

-- ---------------------------------------------------------------------
-- لوحة إدارة المنصة
-- ---------------------------------------------------------------------
create or replace function app.admin_stores_overview()
returns table (store_id uuid, name text, owner_phone text, status text, plan_code text,
               expires_at timestamptz, branches bigint, customers bigint, users bigint,
               last_tx_at timestamptz, created_at timestamptz)
language plpgsql stable security definer set search_path = app, public as $$
begin
  if not app.is_platform_admin() then raise exception 'platform_admin_only'; end if;
  return query
  select s.id, s.name, s.owner_phone, s.status, cs.plan_code, cs.expires_at,
         (select count(*) from app.branches x where x.store_id = s.id),
         (select count(*) from app.customers x where x.store_id = s.id and x.status <> 'archived'),
         (select count(*) from app.app_users x where x.store_id = s.id and x.is_active),
         (select max(x.received_at) from app.transactions x where x.store_id = s.id),
         s.created_at
  from app.stores s
  left join lateral app.current_subscription(s.id) cs on true
  order by s.created_at desc;
end $$;

create or replace function app.admin_set_store_status(p_store uuid, p_status text) returns void
language plpgsql security definer set search_path = app, public as $$
begin
  if not app.is_platform_admin() then raise exception 'platform_admin_only'; end if;
  update app.stores set status = p_status where id = p_store;
end $$;

grant execute on function app.admin_stores_overview(), app.admin_set_store_status(uuid, text) to authenticated;

-- البقالة الموقوفة من الإدارة: لا تسجل حركات جديدة
create or replace function app.tx_store_active() returns trigger
language plpgsql security definer set search_path = app, public as $$
begin
  if (select status from app.stores where id = new.store_id) = 'suspended' then
    raise exception 'store_suspended: الحساب موقوف — تواصل مع الدعم';
  end if;
  return new;
end $$;
create trigger tx_store_active before insert on app.transactions
  for each row execute function app.tx_store_active();

-- ---------------------------------------------------------------------
-- مديرو المنصة: يحصلون على platform_admin في التوكن
-- ---------------------------------------------------------------------
create table app.platform_admins (
  auth_user_id uuid primary key,
  name         text not null,
  created_at   timestamptz not null default now()
);
alter table app.platform_admins enable row level security;

create or replace function public.ajil_access_token_hook(event jsonb) returns jsonb
language plpgsql stable security definer set search_path = app, public as $$
declare
  u app.app_users;
  claims jsonb := coalesce(event->'claims', '{}');
begin
  select * into u from app.app_users
   where auth_user_id = (event->>'user_id')::uuid and is_active;
  if u.id is not null then
    claims := claims || jsonb_build_object(
      'store_id', u.store_id, 'app_user_id', u.id, 'app_role', u.role, 'user_no', u.user_no);
  end if;
  if exists (select 1 from app.platform_admins where auth_user_id = (event->>'user_id')::uuid) then
    claims := claims || jsonb_build_object('platform_admin', true);
  end if;
  return jsonb_set(event, '{claims}', claims);
end $$;
revoke execute on function public.ajil_access_token_hook(jsonb) from public;

do $$
begin
  if exists (select 1 from pg_roles where rolname = 'supabase_auth_admin') then
    grant select on app.platform_admins to supabase_auth_admin;
    create policy hook_read_admins on app.platform_admins for select to supabase_auth_admin using (true);
    grant execute on function public.ajil_access_token_hook(jsonb) to supabase_auth_admin;
  end if;
end $$;

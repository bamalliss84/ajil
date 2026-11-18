-- =====================================================================
-- تقوية العزل بين البقالات (مراجعة أمنية):
--   1) الوعد: الزبون يتبع نفس البقالة والفرع
--   2) created_by يفرضه الخادم في الزبائن والوعود
--   3) has_branch: المستخدم الموقوف يفقد الوصول فوراً (حتى بتوكن ساري)
--   4) فحص المالك بـ is distinct from + سحب EXECUTE من public/anon
--   5) current_subscription: لا تُقرأ اشتراكات بقالة أخرى
--   6) OTP وأكواد التفعيل من مولّد عشوائي آمن (pgcrypto)
-- =====================================================================

-- pgcrypto: في Supabase موجودة في مخطط extensions؛ في PostgreSQL المجرد ننشئها
create schema if not exists extensions;
create extension if not exists pgcrypto with schema extensions;

-- ---------------------------------------------------------------------
-- 1) الوعد: الزبون يتبع نفس البقالة والفرع
-- ---------------------------------------------------------------------
create or replace function app.promise_customer_check() returns trigger
language plpgsql security definer set search_path = app, public as $$
declare
  c app.customers;
begin
  select * into c from app.customers where id = new.customer_id;
  if c.id is null or c.store_id <> new.store_id or c.branch_id <> new.branch_id then
    raise exception 'customer_mismatch: الزبون لا يتبع هذا الفرع';
  end if;
  return new;
end $$;

create trigger promises_customer_check before insert on app.promises
  for each row execute function app.promise_customer_check();

-- ---------------------------------------------------------------------
-- 2) created_by يحدده الخادم من التوكن، لا الجوال
--    (security invoker عمداً: current_user هو دور المتصل الفعلي.
--     مفتاح الخدمة والاتصال المباشر يحتفظان بالقيمة المرسلة للاستيراد والصيانة)
-- ---------------------------------------------------------------------
create or replace function app.force_created_by() returns trigger
language plpgsql security invoker set search_path = app, public as $$
begin
  if current_user in ('authenticated', 'anon') then
    new.created_by := app.app_user_id();
  end if;
  return new;
end $$;

create trigger customers_force_created_by before insert on app.customers
  for each row execute function app.force_created_by();
create trigger promises_force_created_by before insert on app.promises
  for each row execute function app.force_created_by();

-- ---------------------------------------------------------------------
-- 3) has_branch: المستخدم الحالي يجب أن يكون نشطاً في نفس البقالة
-- ---------------------------------------------------------------------
create or replace function app.has_branch(p_branch uuid) returns boolean
language sql stable security definer set search_path = app, public as $$
  select exists (
    select 1
    from app.branches b
    join app.app_users u on u.id = app.app_user_id() and u.store_id = b.store_id and u.is_active
    where b.id = p_branch and b.store_id = app.store_id()
      and (app.user_role() = 'owner'
           or exists (select 1 from app.user_branches ub
                      where ub.branch_id = b.id and ub.user_id = u.id))
  )
$$;

-- ---------------------------------------------------------------------
-- 4) فحص المالك: app_role غائب (null) لا يتجاوز الشرط
-- ---------------------------------------------------------------------
create or replace function app.set_device_state(p_device uuid, p_approve boolean, p_revoke boolean)
returns app.devices
language plpgsql security definer set search_path = app, public as $$
declare d app.devices;
begin
  if app.user_role() is distinct from 'owner' then raise exception 'owner_only'; end if;
  update app.devices set
    approved   = case when p_approve then true else approved end,
    revoked_at = case when p_revoke then now() else revoked_at end
  where id = p_device and store_id = app.store_id()
  returning * into d;
  if d.id is null then raise exception 'device_not_found'; end if;
  return d;
end $$;

create or replace function app.add_employee(p_name text, p_auth_user_id uuid, p_branches uuid[])
returns app.app_users
language plpgsql security definer set search_path = app, public as $$
declare
  u app.app_users;
  lim int;
  cnt int;
  nxt int;
begin
  if app.user_role() is distinct from 'owner' then raise exception 'owner_only'; end if;
  select p.users_limit into lim from app.plans p
   where p.code = (app.current_subscription(app.store_id())).plan_code;
  select count(*) into cnt from app.app_users where store_id = app.store_id() and is_active;
  if lim is not null and cnt >= lim then
    raise exception 'plan_user_limit: وصلت لحد المستخدمين في باقتك (%)', lim;
  end if;
  select coalesce(max(user_no), 1) + 1 into nxt from app.app_users where store_id = app.store_id();
  insert into app.app_users (store_id, user_no, auth_user_id, display_name, role)
  values (app.store_id(), nxt, p_auth_user_id, p_name, 'employee') returning * into u;
  insert into app.user_branches (user_id, branch_id)
  select u.id, b from unnest(p_branches) b
  where exists (select 1 from app.branches where id = b and store_id = app.store_id());
  return u;
end $$;

create or replace function app.add_branch(p_name text)
returns app.branches
language plpgsql security definer set search_path = app, public as $$
declare
  br app.branches;
  nxt int;
begin
  if app.user_role() is distinct from 'owner' then raise exception 'owner_only'; end if;
  select count(*) + 1 into nxt from app.branches where store_id = app.store_id();
  insert into app.branches (store_id, code, name) values (app.store_id(), 'B' || nxt, p_name)
  returning * into br;
  insert into app.user_branches (user_id, branch_id) values (app.app_user_id(), br.id);
  return br;
end $$;

create or replace function app.redeem_code(p_code text) returns app.subscriptions
language plpgsql security definer set search_path = app, public as $$
declare
  ac app.activation_codes;
  cur app.subscriptions;
  s app.subscriptions;
  clean text := upper(replace(replace(p_code, '-', ''), ' ', ''));
begin
  if app.user_role() is distinct from 'owner' then raise exception 'owner_only: التفعيل للمالك فقط'; end if;
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

create or replace function app.set_employee(p_user uuid, p_active boolean, p_branches uuid[] default null)
returns app.app_users
language plpgsql security definer set search_path = app, public as $$
declare u app.app_users;
begin
  if app.user_role() is distinct from 'owner' then raise exception 'owner_only'; end if;
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

-- ---------------------------------------------------------------------
-- 5) current_subscription: بقالتي فقط، إلا لمدير المنصة ومفتاح الخدمة والاتصال المباشر
--    security invoker: عند استدعائها من دالة security definer (الـ triggers وغيرها)
--    يكون current_user مالك الدوال فلا يُطبق الفحص؛ يُطبق فقط على طلبات API المباشرة.
-- ---------------------------------------------------------------------
create or replace function app.current_subscription(p_store uuid)
returns app.subscriptions
language plpgsql stable security invoker set search_path = app, public as $$
declare
  s app.subscriptions;
begin
  if current_user in ('authenticated', 'anon')
     and p_store is distinct from app.store_id()
     and not app.is_platform_admin()
     and coalesce(app.claims() ->> 'role', '') <> 'service_role'
     and app.claims() <> '{}'::jsonb then
    raise exception 'store_mismatch: لا يمكن قراءة اشتراك بقالة أخرى';
  end if;
  select x.* into s from app.subscriptions x
   where x.store_id = p_store and x.starts_at <= now()
   order by x.expires_at desc limit 1;
  return s;
end $$;

-- ---------------------------------------------------------------------
-- 6) مولّد عشوائي آمن للرموز والأكواد
-- ---------------------------------------------------------------------
create or replace function app.otp_issue(p_phone text, p_purpose text) returns text
language plpgsql security definer set search_path = app, public, extensions as $$
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
  -- 48 بت عشوائية آمنة ثم باقي القسمة على مليون (الانحياز مهمل: 10^6 / 2^48)
  code := lpad((('x' || encode(gen_random_bytes(6), 'hex'))::bit(48)::bigint % 1000000)::text, 6, '0');
  insert into app.otp_codes (id, phone, purpose, code_hash, expires_at)
  values (rid, p_phone, p_purpose,
          encode(sha256(convert_to(rid::text || ':' || code, 'UTF8')), 'hex'),
          now() + interval '5 minutes');
  return code;
end $$;

create or replace function app.generate_codes(p_plan text, p_months int, p_count int, p_agent text default null)
returns setof text
language plpgsql security definer set search_path = app, public, extensions as $$
declare
  alphabet constant text := 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';  -- 32 حرفاً بدون المتشابهة (0/O، 1/I)
  i int;
  j int;
  b bytea;
  c text;
begin
  if not (app.is_platform_admin() or app.claims() ->> 'role' = 'service_role' or app.claims() = '{}'::jsonb) then
    raise exception 'platform_admin_only';
  end if;
  for i in 1..p_count loop
    -- 12 حرفاً؛ 256 من مضاعفات 32 فالتوزيع منتظم تماماً
    b := gen_random_bytes(12);
    c := '';
    for j in 0..11 loop
      c := c || substr(alphabet, 1 + get_byte(b, j) % 32, 1);
    end loop;
    insert into app.activation_codes (code, plan_code, months, agent) values (c, p_plan, p_months, p_agent);
    return next substr(c, 1, 4) || '-' || substr(c, 5, 4) || '-' || substr(c, 9, 4);
  end loop;
end $$;

-- ---------------------------------------------------------------------
-- 4ب) صلاحيات EXECUTE: لا شيء لـ public و anon، و authenticated حسب الحاجة فقط
--     (الـ triggers لا تحتاج EXECUTE وقت التشغيل، و pg_cron وخطّاف التوكن يعملان كمالك)
-- ---------------------------------------------------------------------
revoke execute on all functions in schema app from public, anon, authenticated;

-- ملاحظة: PostgreSQL يمنح EXECUTE لـ public على كل دالة جديدة، والصلاحيات الافتراضية
-- على مستوى المخطط لا تسحب ذلك. لذا كل migration تضيف دالة في app يجب أن تكتب:
--   revoke execute on function app.xxx(...) from public, anon;
-- واختبار isolation_test يفشل إن نُسي ذلك.

-- authenticated: دوال الهوية والسياسات (RLS و Realtime تستدعيها بدور المستخدم)
grant execute on function
  app.claims(), app.store_id(), app.app_user_id(), app.user_role(), app.is_platform_admin(),
  app.has_branch(uuid), app.device_ok(uuid), app.via_gateway(), app.can_send_notices(),
  app.current_subscription(uuid)
to authenticated;

-- authenticated: دوال التطبيق والمزامنة (تتحقق داخلياً من الدور والبقالة)
grant execute on function
  app.register_device(text, text), app.register_device_v2(text, text, text),
  app.set_device_state(uuid, boolean, boolean), app.gateway_device_key(uuid, text),
  app.push_transactions(uuid, jsonb), app.device_gaps(uuid),
  app.pull_changes(uuid, bigint, int), app.customer_fingerprints(uuid), app.due_today(uuid, date),
  app.redeem_code(text), app.add_employee(text, uuid, uuid[]), app.add_branch(text),
  app.set_employee(uuid, boolean, uuid[])
to authenticated;

-- authenticated: لوحة الإدارة (كلها تتحقق من platform_admin داخلياً)
grant execute on function
  app.activate_subscription(uuid, text, int, text, int), app.generate_codes(text, int, int, text),
  app.admin_stores_overview(), app.admin_set_store_status(uuid, text),
  app.admin_resolve_alert(bigint), app.admin_summary()
to authenticated;

-- مفتاح الخدمة (Edge Functions): كل دوال app، والدوال القادمة تلقائياً
do $$
begin
  if exists (select 1 from pg_roles where rolname = 'service_role') then
    grant execute on all functions in schema app to service_role;
    alter default privileges in schema app grant execute on functions to service_role;
  end if;
end $$;

-- خطّاف التوكن: يبقى لـ supabase_auth_admin وحده
revoke execute on function public.ajil_access_token_hook(jsonb) from public, anon, authenticated;
do $$
begin
  if exists (select 1 from pg_roles where rolname = 'supabase_auth_admin') then
    grant execute on function public.ajil_access_token_hook(jsonb) to supabase_auth_admin;
  end if;
end $$;

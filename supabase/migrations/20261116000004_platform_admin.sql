-- =====================================================================
-- إدارة المنصة: الباقات، إنشاء البقالة، التفعيل والتجديد
-- هذه الدوال تُستدعى من Edge Functions بمفتاح الخدمة (service_role)
-- أو من لوحة الإدارة بمستخدم platform_admin
-- =====================================================================

insert into app.plans (code, name_ar, customers_limit, users_limit, devices_limit, branches_included, monthly_price, price_currency) values
  ('trial',    'تجربة مجانية', null, 3,    3,    1, 0,     'YER'),
  ('basic',    'أساسية',       200,  1,    2,    1, 5000,  'YER'),
  ('advanced', 'متقدمة',       500,  3,    4,    1, 10000, 'YER'),
  ('premium',  'مميزة',        null, null, null, 1, 15000, 'YER')
on conflict (code) do nothing;

-- إنشاء بقالة جديدة: البقالة + الفرع الرئيسي + المالك (المستخدم 1) + تجربة 30 يوماً
-- p_auth_user_id: حساب Supabase Auth الذي أُنشئ بعد التحقق من OTP
create or replace function app.create_store(
  p_name text, p_owner_phone text, p_owner_name text, p_auth_user_id uuid,
  p_device_key text default null, p_currency text default 'YER')
returns uuid
language plpgsql security definer set search_path = app, public as $$
declare
  s_id uuid;
  b_id uuid;
  u_id uuid;
  trial_ok boolean;
begin
  if exists (select 1 from app.stores where owner_phone = p_owner_phone) then
    raise exception 'phone_taken: هذا الرقم مسجل لبقالة أخرى';
  end if;

  insert into app.stores (name, owner_phone, default_currency)
  values (p_name, p_owner_phone, p_currency) returning id into s_id;

  insert into app.branches (store_id, code, name) values (s_id, 'B1', 'الفرع الرئيسي')
  returning id into b_id;

  insert into app.app_users (store_id, user_no, auth_user_id, display_name, role)
  values (s_id, 1, p_auth_user_id, p_owner_name, 'owner') returning id into u_id;

  insert into app.user_branches (user_id, branch_id) values (u_id, b_id);
  insert into app.store_settings (store_id) values (s_id);

  -- التجربة المجانية مرة واحدة لكل رقم ولكل جهاز
  trial_ok := not exists (select 1 from app.trial_claims
                          where phone = p_owner_phone
                             or (p_device_key is not null and device_key = p_device_key));
  if trial_ok then
    insert into app.trial_claims (phone, device_key) values (p_owner_phone, p_device_key);
    insert into app.subscriptions (store_id, plan_code, expires_at, activated_by)
    values (s_id, 'trial', now() + interval '30 days', 'auto_trial');
  else
    -- بدون تجربة: البقالة تُنشأ لكن تحتاج تفعيلاً قبل تسجيل الحركات
    insert into app.subscriptions (store_id, plan_code, expires_at, activated_by)
    values (s_id, 'basic', now() - interval '8 days', 'no_trial');
  end if;
  return s_id;
end $$;

-- إضافة موظف (المالك فقط): يأخذ رقم المستخدم التالي
create or replace function app.add_employee(p_name text, p_auth_user_id uuid, p_branches uuid[])
returns app.app_users
language plpgsql security definer set search_path = app, public as $$
declare
  u app.app_users;
  lim int;
  cnt int;
  nxt int;
begin
  if app.user_role() <> 'owner' then raise exception 'owner_only'; end if;
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

-- إضافة فرع (المالك فقط)
create or replace function app.add_branch(p_name text)
returns app.branches
language plpgsql security definer set search_path = app, public as $$
declare
  br app.branches;
  nxt int;
begin
  if app.user_role() <> 'owner' then raise exception 'owner_only'; end if;
  select count(*) + 1 into nxt from app.branches where store_id = app.store_id();
  insert into app.branches (store_id, code, name) values (app.store_id(), 'B' || nxt, p_name)
  returning * into br;
  insert into app.user_branches (user_id, branch_id) values (app.app_user_id(), br.id);
  return br;
end $$;

-- تفعيل أو تجديد اشتراك (مدير المنصة): يبدأ من نهاية الاشتراك الحالي إن كان سارياً
create or replace function app.activate_subscription(
  p_store uuid, p_plan text, p_months int, p_payment_ref text default null, p_extra_branches int default 0)
returns app.subscriptions
language plpgsql security definer set search_path = app, public as $$
declare
  cur app.subscriptions;
  st timestamptz;
  s app.subscriptions;
begin
  -- مسموح: مدير المنصة، مفتاح الخدمة، أو اتصال مباشر بقاعدة البيانات (بدون JWT)
  if not (app.is_platform_admin() or app.claims() ->> 'role' = 'service_role' or app.claims() = '{}'::jsonb) then
    raise exception 'platform_admin_only';
  end if;
  cur := app.current_subscription(p_store);
  st := greatest(now(), coalesce(cur.expires_at, now()));
  insert into app.subscriptions (store_id, plan_code, starts_at, expires_at, extra_branches, activated_by, payment_ref)
  values (p_store, p_plan, now(), st + make_interval(months => p_months), p_extra_branches,
          coalesce(app.claims() ->> 'sub', current_user), p_payment_ref)
  returning * into s;
  return s;
end $$;

-- PostgreSQL يمنح EXECUTE للجميع افتراضياً، فنسحبها من public
revoke execute on function app.create_store(text, text, text, uuid, text, text) from public;
grant execute on function app.add_employee(text, uuid, uuid[]) to authenticated;
grant execute on function app.add_branch(text) to authenticated;
grant execute on function app.activate_subscription(uuid, text, int, text, int) to authenticated; -- يتحقق داخلياً من مدير المنصة

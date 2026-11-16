-- =====================================================================
-- العزل (RLS)، الصلاحيات، دوال المزامنة، ربط الجهاز، مطالبات التوكن
-- =====================================================================

-- ---------------------------------------------------------------------
-- الصلاحيات: المستخدم العادي لا يعدّل ولا يحذف الحركات أبداً
-- ---------------------------------------------------------------------
grant usage on schema app to authenticated;
grant select on all tables in schema app to authenticated;
grant insert on app.customers, app.transactions, app.promises to authenticated;
grant update (name, phone, address, notes, default_currency, credit_limit,
              credit_limit_currency, status) on app.customers to authenticated;
grant update (promised_date, amount, currency, note, remind_day_before,
              remind_customer, status) on app.promises to authenticated;
revoke update, delete, truncate on app.transactions from authenticated;
revoke delete, truncate on app.customers, app.promises from authenticated;
grant usage, select on sequence app.sync_seq to authenticated;

-- ---------------------------------------------------------------------
-- الجهاز: مسجل لهذه البقالة، معتمد، وغير ملغى
-- ---------------------------------------------------------------------
create or replace function app.device_ok(p_device uuid) returns boolean
language sql stable security definer set search_path = app, public as $$
  select p_device is not null and exists (
    select 1 from app.devices d
    where d.id = p_device and d.store_id = app.store_id()
      and d.approved and d.revoked_at is null)
$$;

-- ---------------------------------------------------------------------
-- تفعيل RLS على كل الجداول
-- ---------------------------------------------------------------------
alter table app.stores            enable row level security;
alter table app.branches          enable row level security;
alter table app.subscriptions     enable row level security;
alter table app.plans             enable row level security;
alter table app.app_users         enable row level security;
alter table app.user_branches     enable row level security;
alter table app.devices           enable row level security;
alter table app.customers         enable row level security;
alter table app.transactions      enable row level security;
alter table app.customer_balances enable row level security;
alter table app.promises          enable row level security;
alter table app.store_settings    enable row level security;
alter table app.audit_log         enable row level security;
alter table app.trial_claims      enable row level security;

-- القراءة: بقالتي فقط
create policy plans_read    on app.plans    for select to authenticated using (is_active);
create policy stores_read   on app.stores   for select to authenticated using (id = app.store_id());
create policy branches_read on app.branches for select to authenticated
  using (store_id = app.store_id() and app.has_branch(id));
create policy subs_read     on app.subscriptions for select to authenticated using (store_id = app.store_id());
create policy users_read    on app.app_users for select to authenticated using (store_id = app.store_id());
create policy ub_read       on app.user_branches for select to authenticated
  using (exists (select 1 from app.app_users u where u.id = user_id and u.store_id = app.store_id()));
create policy devices_read  on app.devices  for select to authenticated
  using (store_id = app.store_id() and app.user_role() = 'owner');
create policy settings_read on app.store_settings for select to authenticated using (store_id = app.store_id());
create policy audit_read    on app.audit_log for select to authenticated
  using (store_id = app.store_id() and app.user_role() = 'owner');

-- البيانات التشغيلية: بقالتي + فرع مسموح لي
create policy customers_rw on app.customers for all to authenticated
  using (store_id = app.store_id() and app.has_branch(branch_id))
  with check (store_id = app.store_id() and app.has_branch(branch_id));

create policy tx_read on app.transactions for select to authenticated
  using (store_id = app.store_id() and app.has_branch(branch_id));
create policy tx_insert on app.transactions for insert to authenticated
  with check (store_id = app.store_id() and app.has_branch(branch_id)
              and created_by = app.app_user_id()
              and app.device_ok(device_id));

create policy balances_read on app.customer_balances for select to authenticated
  using (store_id = app.store_id() and app.has_branch(branch_id));

create policy promises_rw on app.promises for all to authenticated
  using (store_id = app.store_id() and app.has_branch(branch_id))
  with check (store_id = app.store_id() and app.has_branch(branch_id));

-- تسجيل الجهاز عند أول دخول. جهاز مالك يُعتمد تلقائياً، جهاز موظف ينتظر المالك
create or replace function app.register_device(p_device_key text, p_label text default null)
returns app.devices
language plpgsql security definer set search_path = app, public as $$
declare
  d app.devices;
  other_store uuid;
  lim int;
  cnt int;
  letter text;
begin
  if app.store_id() is null then raise exception 'not_authenticated'; end if;

  select store_id into other_store from app.devices
   where device_key = p_device_key and revoked_at is null;
  if other_store is not null and other_store <> app.store_id() then
    raise exception 'device_bound_elsewhere: هذا الجهاز مسجل لبقالة أخرى — يجب إلغاؤه من حسابها أولاً';
  end if;

  select * into d from app.devices
   where device_key = p_device_key and store_id = app.store_id() and revoked_at is null;
  if d.id is not null then return d; end if;

  select p.devices_limit into lim from app.plans p
   where p.code = (app.current_subscription(app.store_id())).plan_code;
  select count(*) into cnt from app.devices where store_id = app.store_id() and revoked_at is null;
  if lim is not null and cnt >= lim then
    raise exception 'plan_device_limit: وصلت لحد الأجهزة في باقتك (%)', lim;
  end if;

  select chr(65 + count(*)::int) into letter from app.devices where store_id = app.store_id();
  insert into app.devices (store_id, device_key, label, device_letter, approved)
  values (app.store_id(), p_device_key, p_label, letter, app.user_role() = 'owner')
  returning * into d;
  return d;
end $$;

-- المالك: اعتماد أو إلغاء جهاز
create or replace function app.set_device_state(p_device uuid, p_approve boolean, p_revoke boolean)
returns app.devices
language plpgsql security definer set search_path = app, public as $$
declare d app.devices;
begin
  if app.user_role() <> 'owner' then raise exception 'owner_only'; end if;
  update app.devices set
    approved   = case when p_approve then true else approved end,
    revoked_at = case when p_revoke then now() else revoked_at end
  where id = p_device and store_id = app.store_id()
  returning * into d;
  if d.id is null then raise exception 'device_not_found'; end if;
  return d;
end $$;

-- ---------------------------------------------------------------------
-- المزامنة
-- ---------------------------------------------------------------------
-- رفع الحركات: آمن للتكرار (نفس الـ id لا يُدخل مرتين)
-- يرجع لكل حركة: accepted | duplicate | rejected + السبب
create or replace function app.push_transactions(p_device uuid, p_rows jsonb)
returns table (id uuid, status text, server_seq bigint, error text)
language plpgsql security invoker set search_path = app, public as $$
declare
  r jsonb;
  tx app.transactions;
begin
  for r in select * from jsonb_array_elements(p_rows) loop
    select * into tx from app.transactions t where t.id = (r->>'id')::uuid;
    if tx.id is not null then
      id := tx.id; status := 'duplicate'; server_seq := tx.server_seq; error := null;
      return next; continue;
    end if;
    begin
      insert into app.transactions (id, store_id, branch_id, customer_id, kind, amount, currency,
        signed_amount, fx_paid_amount, fx_paid_currency, fx_rate, voided_id, void_reason,
        description, invoice_no, due_date, created_by, device_id, device_seq, created_at)
      values ((r->>'id')::uuid, app.store_id(), (r->>'branch_id')::uuid, (r->>'customer_id')::uuid,
        r->>'kind', (r->>'amount')::numeric, r->>'currency', 0,
        (r->>'fx_paid_amount')::numeric, r->>'fx_paid_currency', (r->>'fx_rate')::numeric,
        (r->>'voided_id')::uuid, r->>'void_reason', r->>'description', r->>'invoice_no',
        (r->>'due_date')::date, app.app_user_id(), p_device, (r->>'device_seq')::bigint,
        coalesce((r->>'created_at')::timestamptz, now()))
      returning * into tx;
      id := tx.id; status := 'accepted'; server_seq := tx.server_seq; error := null;
    exception when others then
      id := (r->>'id')::uuid; status := 'rejected'; server_seq := null; error := sqlerrm;
    end;
    return next;
  end loop;
end $$;

-- الفجوات في تسلسل جهاز: الأرقام الناقصة التي يجب أن يعيد الجوال إرسالها
create or replace function app.device_gaps(p_device uuid)
returns table (missing_seq bigint)
language sql stable security invoker set search_path = app, public as $$
  with s as (select device_seq from app.transactions where device_id = p_device)
  select g from generate_series(1, (select coalesce(max(device_seq), 0) from s)) g
  where g not in (select device_seq from s)
$$;

-- السحب: كل ما تغيّر في الفرع بعد مؤشر المزامنة
create or replace function app.pull_changes(p_branch uuid, p_since bigint, p_limit int default 500)
returns jsonb
language sql stable security invoker set search_path = app, public as $$
  select jsonb_build_object(
    'customers', coalesce((select jsonb_agg(c order by c.server_seq) from (
        select * from app.customers where branch_id = p_branch and server_seq > p_since
        order by server_seq limit p_limit) c), '[]'),
    'transactions', coalesce((select jsonb_agg(t order by t.server_seq) from (
        select * from app.transactions where branch_id = p_branch and server_seq > p_since
        order by server_seq limit p_limit) t), '[]'),
    'promises', coalesce((select jsonb_agg(p order by p.server_seq) from (
        select * from app.promises where branch_id = p_branch and server_seq > p_since
        order by server_seq limit p_limit) p), '[]'),
    'max_seq', (select coalesce(max(m), p_since) from (
        select max(server_seq) m from app.customers where branch_id = p_branch
        union all select max(server_seq) from app.transactions where branch_id = p_branch
        union all select max(server_seq) from app.promises where branch_id = p_branch) x)
  )
$$;

-- بصمة المطابقة لكل زبون: عدد الحركات ومجموعها لكل عملة
create or replace function app.customer_fingerprints(p_branch uuid)
returns table (customer_id uuid, currency text, tx_count bigint, tx_sum numeric)
language sql stable security invoker set search_path = app, public as $$
  select customer_id, currency, count(*), sum(signed_amount)
  from app.transactions where branch_id = p_branch
  group by customer_id, currency
$$;

-- فحص سلسلة البصمات لفرع: يرجع أول حركة مكسورة إن وجدت
create or replace function app.verify_chain(p_branch uuid)
returns table (ok boolean, broken_at uuid, checked bigint)
language plpgsql stable security definer set search_path = app, public as $$
declare
  t app.transactions;
  prev text := 'GENESIS';
  n bigint := 0;
begin
  for t in select * from app.transactions where branch_id = p_branch order by server_seq loop
    n := n + 1;
    if t.prev_hash <> prev or t.hash <> app.tx_hash(t) then
      ok := false; broken_at := t.id; checked := n; return next; return;
    end if;
    prev := t.hash;
  end loop;
  ok := true; broken_at := null; checked := n; return next;
end $$;

-- مطابقة الرصيد المخزّن مع مجموع الحركات (للفحص اليومي)
create or replace function app.balance_mismatches()
returns table (customer_id uuid, currency text, stored numeric, computed numeric)
language sql stable security definer set search_path = app, public as $$
  select b.customer_id, b.currency, b.balance, coalesce(s.total, 0)
  from app.customer_balances b
  left join (select customer_id, currency, sum(signed_amount) total
             from app.transactions group by 1, 2) s
    on s.customer_id = b.customer_id and s.currency = b.currency
  where b.balance <> coalesce(s.total, 0)
$$;

grant execute on all functions in schema app to authenticated;
revoke execute on function app.verify_chain(uuid), app.balance_mismatches() from public, authenticated;

-- ---------------------------------------------------------------------
-- مطالبات التوكن (Supabase Custom Access Token Hook)
-- تضيف store_id و app_user_id و app_role إلى JWT عند الدخول
-- ---------------------------------------------------------------------
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
  return jsonb_set(event, '{claims}', claims);
end $$;

revoke execute on function public.ajil_access_token_hook(jsonb) from public;

do $$
begin
  if exists (select 1 from pg_roles where rolname = 'supabase_auth_admin') then
    grant usage on schema app to supabase_auth_admin;
    grant select on app.app_users to supabase_auth_admin;
    grant execute on function public.ajil_access_token_hook(jsonb) to supabase_auth_admin;
    
    create policy hook_read_users on app.app_users for select to supabase_auth_admin using (true);
  end if;
end $$;

-- =====================================================================
-- رابط كشف الحساب العام للزبون
--   * رابط واحد لكل زبون (token عشوائي 128 بت، base64url)
--   * صفحة web/statement تستدعي app.public_statement بمفتاح anon
--   * الرد للقراءة فقط وبدون أي بيانات حساسة أو معرّفات
-- =====================================================================

create table app.statement_links (
  customer_id     uuid primary key references app.customers(id),
  store_id        uuid not null references app.stores(id),
  branch_id       uuid not null references app.branches(id),
  token           text not null unique,
  created_by      uuid references app.app_users(id),
  created_at      timestamptz not null default now(),
  revoked_at      timestamptz,
  last_viewed_at  timestamptz,
  view_count      int not null default 0
);
create index on app.statement_links (store_id, branch_id);

alter table app.statement_links enable row level security;
-- القراءة فقط عبر API، والكتابة عبر الدوال (security definer)
grant select on app.statement_links to authenticated;
revoke insert, update, delete, truncate on app.statement_links from authenticated;
create policy statement_links_read on app.statement_links for select to authenticated
  using (store_id = app.store_id() and app.has_branch(branch_id));

do $$
begin
  if exists (select 1 from pg_roles where rolname = 'service_role') then
    grant all on app.statement_links to service_role;
  end if;
end $$;

-- الصفحة العامة تستدعي دالة واحدة بدور anon (بدون أي صلاحية على الجداول)
grant usage on schema app to anon;

-- ---------------------------------------------------------------------
-- token: 16 بايت عشوائية آمنة ← base64url بدون padding (22 حرفاً)
-- ---------------------------------------------------------------------
create or replace function app.new_statement_token() returns text
language sql volatile set search_path = app, public, extensions as $$
  select rtrim(translate(encode(gen_random_bytes(16), 'base64'), '+/', '-_'), '=')
$$;

-- ---------------------------------------------------------------------
-- جلب أو إنشاء رابط الزبون (p_regenerate: يُبطل القديم ويُنشئ جديداً)
-- ---------------------------------------------------------------------
create or replace function app.statement_link(p_customer uuid, p_regenerate boolean default false)
returns text
language plpgsql security definer set search_path = app, public as $$
declare
  c  app.customers;
  l  app.statement_links;
begin
  select * into c from app.customers where id = p_customer;
  if c.id is null or c.store_id is distinct from app.store_id() or not app.has_branch(c.branch_id) then
    raise exception 'customer_not_found: الزبون غير موجود';
  end if;

  select * into l from app.statement_links where customer_id = p_customer for update;
  if l.customer_id is not null and l.revoked_at is null and not coalesce(p_regenerate, false) then
    return l.token;
  end if;

  -- التجديد (أو إعادة تفعيل رابط ملغى) للمالك، أو للموظف إن سمح المالك بإرسال الأرصدة
  if l.customer_id is not null and not app.can_send_notices() then
    raise exception 'statement_link_forbidden: تجديد الرابط للمالك فقط';
  end if;
  if c.status = 'archived' then
    raise exception 'customer_archived: لا يُنشأ رابط لزبون مؤرشف';
  end if;

  insert into app.statement_links (customer_id, store_id, branch_id, token, created_by)
  values (c.id, c.store_id, c.branch_id, app.new_statement_token(), app.app_user_id())
  on conflict (customer_id) do update set
    token = excluded.token, created_by = excluded.created_by, created_at = now(),
    revoked_at = null, last_viewed_at = null, view_count = 0
  returning * into l;
  return l.token;
end $$;

-- إلغاء الرابط بدون إنشاء بديل
create or replace function app.revoke_statement_link(p_customer uuid) returns void
language plpgsql security definer set search_path = app, public as $$
declare
  c app.customers;
begin
  select * into c from app.customers where id = p_customer;
  if c.id is null or c.store_id is distinct from app.store_id() or not app.has_branch(c.branch_id) then
    raise exception 'customer_not_found: الزبون غير موجود';
  end if;
  if not app.can_send_notices() then
    raise exception 'statement_link_forbidden: إلغاء الرابط للمالك فقط';
  end if;
  update app.statement_links set revoked_at = now()
   where customer_id = p_customer and revoked_at is null;
end $$;

-- ---------------------------------------------------------------------
-- الكشف العام: نفس الرد (null) لأي رابط غير صالح، ولا معرّفات ولا بيانات حساسة
-- ---------------------------------------------------------------------
create or replace function app.public_statement(p_token text) returns jsonb
language plpgsql security definer set search_path = app, public as $$
declare
  l  app.statement_links;
  c  app.customers;
  st app.stores;
  br app.branches;
  r  jsonb;
begin
  if p_token is null or p_token !~ '^[A-Za-z0-9_-]{22}$' then
    return null;
  end if;
  select * into l from app.statement_links where token = p_token and revoked_at is null;
  if l.customer_id is null then return null; end if;
  select * into c  from app.customers where id = l.customer_id;
  select * into st from app.stores where id = l.store_id;
  if c.status = 'archived' or st.status <> 'active' then return null; end if;
  select * into br from app.branches where id = l.branch_id;

  update app.statement_links set last_viewed_at = now(), view_count = view_count + 1
   where customer_id = l.customer_id;

  select jsonb_build_object(
    'store_name',    st.name,
    'branch_name',   br.name,
    'customer_name', c.name,
    'generated_at',  now(),
    -- الرصيد من الخادم، والإجماليات بدون الحركات الملغاة وقيودها (مطابقة لقائمة الحركات)
    'balances', coalesce((
      select jsonb_agg(jsonb_build_object(
               'currency', b.currency, 'balance', b.balance,
               'total_debit',  coalesce(s.debit, 0), 'total_credit', coalesce(s.credit, 0))
             order by b.currency)
      from app.customer_balances b
      left join lateral (
        select sum(greatest(x.signed_amount, 0)) debit, sum(greatest(-x.signed_amount, 0)) credit
        from app.transactions x
        where x.customer_id = c.id and x.currency = b.currency and x.kind <> 'void'
          and not exists (select 1 from app.transactions v where v.voided_id = x.id)) s on true
      where b.customer_id = c.id), '[]'::jsonb),
    'transactions', coalesce((
      select jsonb_agg(jsonb_build_object(
               'date', t.created_at, 'kind', t.kind, 'amount', t.amount,
               'currency', t.currency, 'description', t.description)
             order by t.created_at desc, t.server_seq desc)
      from (select * from app.transactions x
            where x.customer_id = c.id and x.kind <> 'void'
              and not exists (select 1 from app.transactions v where v.voided_id = x.id)
            order by x.created_at desc, x.server_seq desc
            limit 50) t), '[]'::jsonb),
    'promises', coalesce((
      select jsonb_agg(jsonb_build_object(
               'date', p.promised_date, 'amount', p.amount, 'currency', p.currency)
             order by p.promised_date)
      from app.promises p where p.customer_id = c.id and p.status = 'open'), '[]'::jsonb)
  ) into r;
  return r;
end $$;

-- ---------------------------------------------------------------------
-- EXECUTE: لا شيء افتراضياً، ثم منح صريح
-- ---------------------------------------------------------------------
revoke execute on function app.new_statement_token(), app.statement_link(uuid, boolean),
  app.revoke_statement_link(uuid), app.public_statement(text) from public, anon, authenticated;
grant execute on function app.statement_link(uuid, boolean), app.revoke_statement_link(uuid) to authenticated;
grant execute on function app.public_statement(text) to anon;   -- الدالة الوحيدة المتاحة لـ anon

-- =====================================================================
-- مظهران قابلان للتبديل (classic | ocean) — لكل مستخدم لا لكل بقالة
--   * app.app_users.theme، ولا update مباشر على الجدول
--   * app.set_my_theme: كل مستخدم يغيّر مظهره هو فقط
--   * app.public_statement يرجع مظهر مالك البقالة (user_no = 1) لا مظهر من أرسل الرابط
-- =====================================================================

alter table app.app_users add column theme text not null default 'classic'
  check (theme in ('classic', 'ocean'));

create or replace function app.set_my_theme(p_theme text) returns text
language plpgsql security definer set search_path = app, public as $$
declare
  t text;
begin
  if p_theme is null or p_theme not in ('classic', 'ocean') then
    raise exception 'theme_invalid: المظهر غير معروف';
  end if;
  if app.app_user_id() is null then
    raise exception 'not_authenticated: سجّل الدخول أولاً';
  end if;
  update app.app_users set theme = p_theme
   where id = app.app_user_id() and store_id = app.store_id() and is_active
  returning theme into t;
  if t is null then
    raise exception 'user_not_found: المستخدم غير موجود';
  end if;
  return t;
end $$;

revoke execute on function app.set_my_theme(text) from public, anon;
grant execute on function app.set_my_theme(text) to authenticated;

-- الكشف العام: نفس migration 13 + 'theme' من مالك البقالة
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
    'theme',         coalesce((select u.theme from app.app_users u
                               where u.store_id = l.store_id and u.user_no = 1), 'classic'),
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

-- create or replace يحتفظ بالصلاحيات، لكن نعيد تأكيدها صراحة
revoke execute on function app.public_statement(text) from public, authenticated;
grant execute on function app.public_statement(text) to anon;

-- =====================================================================
-- قراءة مدير المنصة: الأكواد، كل الاشتراكات (للدخل)، تنبيهات السلامة، حلّ التنبيه
-- =====================================================================
create policy codes_admin_read on app.activation_codes for select to authenticated using (app.is_platform_admin());
create policy subs_admin_read on app.subscriptions for select to authenticated using (app.is_platform_admin());
grant select on app.activation_codes, app.integrity_alerts to authenticated;

create or replace function app.admin_resolve_alert(p_id bigint) returns void
language plpgsql security definer set search_path = app, public as $$
begin
  if not app.is_platform_admin() then raise exception 'platform_admin_only'; end if;
  update app.integrity_alerts set resolved = true where id = p_id;
end $$;
grant execute on function app.admin_resolve_alert(bigint) to authenticated;

-- ملخص لوحة الإدارة
create or replace function app.admin_summary()
returns jsonb
language plpgsql stable security definer set search_path = app, public as $$
declare r jsonb;
begin
  if not app.is_platform_admin() then raise exception 'platform_admin_only'; end if;
  with cur as (
    select s.id, cs.plan_code, cs.expires_at
    from app.stores s left join lateral app.current_subscription(s.id) cs on true
  )
  select jsonb_build_object(
    'stores', (select count(*) from cur),
    'trial', (select count(*) from cur where plan_code = 'trial' and expires_at > now()),
    'paying', (select count(*) from cur where plan_code <> 'trial' and expires_at > now()),
    'expired', (select count(*) from cur where expires_at <= now()),
    'expiring_7d', (select count(*) from cur where expires_at between now() and now() + interval '7 days'),
    'mrr', (select coalesce(sum(p.monthly_price), 0) from cur join app.plans p on p.code = cur.plan_code
            where cur.expires_at > now() and cur.plan_code <> 'trial'),
    'open_alerts', (select count(*) from app.integrity_alerts where not resolved),
    'tx_today', (select count(*) from app.transactions where received_at >= date_trunc('day', now()))
  ) into r;
  return r;
end $$;
grant execute on function app.admin_summary() to authenticated;

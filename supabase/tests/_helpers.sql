-- دوال مساعدة مشتركة للاختبارات
create schema if not exists test;
grant usage on schema test to authenticated;

create or replace function test.ok(cond boolean, msg text) returns void
language plpgsql as $$
begin
  if cond is not true then raise exception 'FAIL: %', msg; end if;
  raise notice '✓ %', msg;
end $$;

-- ينفّذ أمراً ويتأكد أنه فشل بخطأ يحتوي النص المتوقع
create or replace function test.fails(q text, pattern text, msg text) returns void
language plpgsql as $$
begin
  begin
    execute q;
  exception when others then
    if sqlerrm ilike '%' || pattern || '%' then
      raise notice '✓ %', msg; return;
    end if;
    raise exception 'FAIL: % — خطأ غير متوقع: %', msg, sqlerrm;
  end;
  raise exception 'FAIL: % — نجح الأمر وكان يجب أن يفشل', msg;
end $$;
grant execute on all functions in schema test to authenticated;

create or replace function test.login(p_store uuid, p_user uuid, p_role text) returns void
language sql as $$
  select set_config('request.jwt.claims',
    jsonb_build_object('store_id', p_store, 'app_user_id', p_user, 'app_role', p_role, 'role', 'authenticated')::text, false)
$$;


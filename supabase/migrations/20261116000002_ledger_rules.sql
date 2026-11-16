-- =====================================================================
-- قواعد السجل المالي: الهوية من التوكن، منع التعديل، الإشارة، الإلغاء،
-- سلسلة البصمات، الأرصدة، حدود الباقات، سجل التدقيق
-- =====================================================================

-- ---------------------------------------------------------------------
-- هوية الطلب من JWT (Supabase يضع المطالبات في request.jwt.claims)
-- ---------------------------------------------------------------------
create or replace function app.claims() returns jsonb
language sql stable as $$
  select coalesce(nullif(current_setting('request.jwt.claims', true), ''), '{}')::jsonb
$$;

create or replace function app.store_id() returns uuid
language sql stable as $$ select nullif(app.claims() ->> 'store_id', '')::uuid $$;

create or replace function app.app_user_id() returns uuid
language sql stable as $$ select nullif(app.claims() ->> 'app_user_id', '')::uuid $$;

create or replace function app.user_role() returns text
language sql stable as $$ select app.claims() ->> 'app_role' $$;

create or replace function app.is_platform_admin() returns boolean
language sql stable as $$ select coalesce((app.claims() ->> 'platform_admin')::boolean, false) $$;

-- هل يحق للمستخدم الحالي الوصول لهذا الفرع؟
create or replace function app.has_branch(p_branch uuid) returns boolean
language sql stable security definer set search_path = app, public as $$
  select exists (
    select 1 from app.branches b
    where b.id = p_branch and b.store_id = app.store_id()
      and (app.user_role() = 'owner'
           or exists (select 1 from app.user_branches ub
                      where ub.branch_id = b.id and ub.user_id = app.app_user_id()))
  )
$$;

-- الاشتراك الحالي (آخر اشتراك ساري)
create or replace function app.current_subscription(p_store uuid)
returns app.subscriptions
language sql stable security definer set search_path = app, public as $$
  select s.* from app.subscriptions s
  where s.store_id = p_store and s.starts_at <= now()
  order by s.expires_at desc limit 1
$$;

-- ---------------------------------------------------------------------
-- 1) منع تعديل أو حذف الحركات المالية نهائياً
-- ---------------------------------------------------------------------
create or replace function app.tx_immutable() returns trigger
language plpgsql as $$
begin
  raise exception 'ledger_immutable: الحركات المالية لا تُعدَّل ولا تُحذف — استخدم الإلغاء (قيد عكسي)'
    using errcode = 'P0001';
end $$;

create trigger tx_no_update before update on app.transactions
  for each row execute function app.tx_immutable();
create trigger tx_no_delete before delete on app.transactions
  for each row execute function app.tx_immutable();

-- ---------------------------------------------------------------------
-- 2) قبل إدخال حركة: التحقق، حساب الإشارة، قواعد الإلغاء، البصمة
-- ---------------------------------------------------------------------
create or replace function app.tx_before_insert() returns trigger
language plpgsql security definer set search_path = app, public as $$
declare
  c        app.customers;
  orig     app.transactions;
  st       app.stores;
  sub      app.subscriptions;
  hrs      int;
  prev     text;
begin
  -- القيم التي يحددها الخادم وحده
  new.received_at := now();
  new.server_seq  := nextval('app.sync_seq');

  select * into c from app.customers where id = new.customer_id;
  if c.id is null or c.store_id <> new.store_id or c.branch_id <> new.branch_id then
    raise exception 'customer_mismatch: الزبون لا يتبع هذا الفرع';
  end if;
  if c.status = 'archived' then
    raise exception 'customer_archived: لا تُسجَّل حركات على زبون مؤرشف';
  end if;

  select * into st from app.stores where id = new.store_id;
  if not (new.currency = any (st.enabled_currencies)) then
    raise exception 'currency_not_enabled: العملة % غير مفعلة في البقالة', new.currency;
  end if;

  -- الاشتراك: يُسمح بالمزامنة حتى 7 أيام بعد الانتهاء ثم وضع القراءة فقط
  sub := app.current_subscription(new.store_id);
  if sub.id is null or now() > sub.expires_at + interval '7 days' then
    raise exception 'subscription_expired: الاشتراك منتهٍ — البيانات للقراءة فقط';
  end if;

  if new.kind = 'void' then
    select * into orig from app.transactions where id = new.voided_id;
    if orig.id is null or orig.customer_id <> new.customer_id then
      raise exception 'void_invalid: الحركة الأصلية غير موجودة لهذا الزبون';
    end if;
    if orig.kind = 'void' then
      raise exception 'void_of_void: لا يمكن إلغاء إلغاء — سجّل حركة جديدة';
    end if;
    if coalesce(new.void_reason, '') = '' then
      raise exception 'void_reason_required: سبب الإلغاء مطلوب';
    end if;
    -- الموظف: يلغي حركاته هو فقط وخلال المدة المحددة
    if app.user_role() = 'employee' then
      select employee_void_hours into hrs from app.store_settings where store_id = new.store_id;
      hrs := coalesce(hrs, 24);
      if orig.created_by <> app.app_user_id() then
        raise exception 'void_not_owner: الموظف يلغي حركاته فقط';
      end if;
      if now() - orig.received_at > make_interval(hours => hrs) then
        raise exception 'void_too_late: انتهت مهلة الإلغاء للموظف — يحتاج موافقة المالك';
      end if;
    end if;
    new.amount        := orig.amount;
    new.currency      := orig.currency;
    new.signed_amount := -orig.signed_amount;
  elsif new.kind in ('opening','debt') then
    new.signed_amount := new.amount;
  else -- payment, payment_fx, return, discount
    new.signed_amount := -new.amount;
  end if;

  -- سلسلة البصمات لكل فرع: نقفل الفرع حتى لا تتداخل حركتان
  perform pg_advisory_xact_lock(hashtextextended(new.branch_id::text, 0));
  select t.hash into prev from app.transactions t
   where t.branch_id = new.branch_id order by t.server_seq desc limit 1;
  new.prev_hash := coalesce(prev, 'GENESIS');
  new.hash := app.tx_hash(new);
  return new;
end $$;

-- البصمة: SHA-256 لحقول الحركة + بصمة السابقة
create or replace function app.tx_hash(t app.transactions) returns text
language sql immutable as $$
  select encode(sha256(convert_to(concat_ws('|',
    t.prev_hash, t.id, t.store_id, t.branch_id, t.customer_id, t.kind,
    t.amount::text, t.currency, t.signed_amount::text, t.voided_id,
    t.created_by, t.created_at::text, t.server_seq::text), 'UTF8')), 'hex')
$$;

create trigger tx_before_insert before insert on app.transactions
  for each row execute function app.tx_before_insert();

-- ---------------------------------------------------------------------
-- 3) بعد إدخال حركة: تحديث الرصيد المخزّن
-- ---------------------------------------------------------------------
create or replace function app.tx_after_insert() returns trigger
language plpgsql security definer set search_path = app, public as $$
begin
  insert into app.customer_balances as b
    (customer_id, currency, store_id, branch_id, balance, total_debit, total_credit, last_tx_at)
  values (new.customer_id, new.currency, new.store_id, new.branch_id, new.signed_amount,
          greatest(new.signed_amount, 0), greatest(-new.signed_amount, 0), new.created_at)
  on conflict (customer_id, currency) do update set
    balance      = b.balance + excluded.balance,
    total_debit  = b.total_debit + excluded.total_debit,
    total_credit = b.total_credit + excluded.total_credit,
    last_tx_at   = greatest(b.last_tx_at, excluded.last_tx_at);

  -- آخر مزامنة للجهاز
  if new.device_id is not null then
    update app.devices set last_sync_at = now() where id = new.device_id;
  end if;
  return null;
end $$;

create trigger tx_after_insert after insert on app.transactions
  for each row execute function app.tx_after_insert();

-- ---------------------------------------------------------------------
-- 4) الزبائن: حد الباقة، تحديث مؤشر المزامنة، سجل التدقيق
-- ---------------------------------------------------------------------
create or replace function app.customer_before_write() returns trigger
language plpgsql security definer set search_path = app, public as $$
declare
  sub app.subscriptions;
  lim int;
  cnt int;
begin
  if tg_op = 'UPDATE' then
    -- لا يتغير انتماء الزبون
    if new.store_id <> old.store_id or new.branch_id <> old.branch_id or new.id <> old.id then
      raise exception 'customer_move_forbidden: نقل الزبون بين الفروع يكون بقيد إغلاق ورصيد افتتاحي';
    end if;
    new.created_at := old.created_at;
    new.created_by := old.created_by;
  end if;
  new.updated_at := now();
  new.server_seq := nextval('app.sync_seq');

  -- حد الباقة: يُحسب على الزبائن غير المؤرشفين في الفرع
  if new.status <> 'archived' and (tg_op = 'INSERT' or old.status = 'archived') then
    sub := app.current_subscription(new.store_id);
    select p.customers_limit into lim from app.plans p where p.code = sub.plan_code;
    if lim is not null then
      select count(*) into cnt from app.customers
       where branch_id = new.branch_id and status <> 'archived' and id <> new.id;
      if cnt >= lim then
        raise exception 'plan_customer_limit: وصلت لحد الباقة (% زبون) — رقِّ الباقة أو أرشف زبائن', lim;
      end if;
    end if;
  end if;
  return new;
end $$;

create trigger customer_before_write before insert or update on app.customers
  for each row execute function app.customer_before_write();

create or replace function app.audit_row() returns trigger
language plpgsql security definer set search_path = app, public as $$
begin
  insert into app.audit_log (store_id, table_name, row_id, action, old_data, new_data, actor)
  values (coalesce(new.store_id, old.store_id), tg_table_name, coalesce(new.id, old.id), tg_op,
          case when tg_op = 'INSERT' then null else to_jsonb(old) end,
          case when tg_op = 'DELETE' then null else to_jsonb(new) end,
          app.app_user_id());
  return null;
end $$;

create trigger customers_audit after update on app.customers
  for each row execute function app.audit_row();
create trigger app_users_audit after insert or update on app.app_users
  for each row execute function app.audit_row();
create trigger devices_audit after insert or update on app.devices
  for each row execute function app.audit_row();

-- الزبائن لا تُحذف (أرشفة فقط)
create or replace function app.no_delete() returns trigger
language plpgsql as $$
begin
  raise exception 'delete_forbidden: لا يُحذف هذا السجل — استخدم الأرشفة أو الإلغاء';
end $$;
create trigger customers_no_delete before delete on app.customers
  for each row execute function app.no_delete();

-- الوعود: مؤشر المزامنة
create or replace function app.touch_sync() returns trigger
language plpgsql as $$
begin
  new.updated_at := now();
  new.server_seq := nextval('app.sync_seq');
  return new;
end $$;
create trigger promises_touch before insert or update on app.promises
  for each row execute function app.touch_sync();

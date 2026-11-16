-- =====================================================================
-- إرسال الأرصدة الجماعي (حتى تاريخ معيّن)
-- الإرسال يتم من واتساب صاحب البقالة بضغطة لكل زبون؛ هنا فقط:
--   * سجل لكل رسالة أُرسلت (لمنع التكرار بين الأجهزة، وكمرجع عند الخلاف)
--   * قالب الرسالة وصلاحية الموظفين في إعدادات البقالة
-- =====================================================================

alter table app.store_settings
  add column employees_can_send_notices boolean not null default false,
  add column balance_notice_template text not null default
    E'السلام عليكم {الاسم}،\nرصيدكم لدى {البقالة} حتى تاريخ {التاريخ}: {الرصيد}.\nإذا سددتم بعد هذا التاريخ فتجاهلوا هذه الرسالة. شكراً لتعاملكم معنا.';

grant update (employees_can_send_notices, balance_notice_template) on app.store_settings to authenticated;

create table app.balance_notices (
  id           uuid primary key,                     -- يولّده الجوال (إعادة الرفع آمنة)
  store_id     uuid not null references app.stores(id),
  branch_id    uuid not null references app.branches(id),
  customer_id  uuid not null references app.customers(id),
  batch_id     uuid not null,                        -- دفعة الإرسال الواحدة
  as_of        date not null,                        -- الرصيد حتى هذا التاريخ
  balances     jsonb not null,                       -- {"YER":"20000.00","SAR":"-20.00"} موجب = عليه
  channel      text not null default 'whatsapp' check (channel in ('whatsapp','sms','manual')),
  sent_by      uuid not null references app.app_users(id),
  sent_at      timestamptz not null default now(),
  check (jsonb_typeof(balances) = 'object')
);
create index balance_notices_customer on app.balance_notices (customer_id, sent_at desc);
create index balance_notices_branch   on app.balance_notices (branch_id, sent_at desc);

-- هل يحق للمستخدم الحالي إرسال الأرصدة؟ المالك دائماً، والموظف إن سمح المالك
create or replace function app.can_send_notices() returns boolean
language sql stable security definer set search_path = app, public as $$
  select app.user_role() = 'owner'
      or coalesce((select employees_can_send_notices from app.store_settings where store_id = app.store_id()), false)
$$;
revoke execute on function app.can_send_notices() from public;
grant execute on function app.can_send_notices() to authenticated;

alter table app.balance_notices enable row level security;
grant select, insert on app.balance_notices to authenticated;
revoke update, delete, truncate on app.balance_notices from authenticated;

create policy notices_read on app.balance_notices for select to authenticated
  using (store_id = app.store_id() and app.has_branch(branch_id));

create policy notices_insert on app.balance_notices for insert to authenticated
  with check (
    store_id = app.store_id()
    and app.has_branch(branch_id)
    and sent_by = app.app_user_id()
    and app.can_send_notices()
    and exists (select 1 from app.customers c
                where c.id = customer_id and c.store_id = app.store_id() and c.branch_id = balance_notices.branch_id)
  );

-- السجل لا يُعدّل ولا يُحذف (مثل الحركات)
create or replace function app.notice_immutable() returns trigger
language plpgsql as $$
begin
  raise exception 'notice_immutable: سجل الإرسال لا يُعدَّل ولا يُحذف' using errcode = 'P0001';
end $$;
create trigger balance_notices_immutable before update or delete on app.balance_notices
  for each row execute function app.notice_immutable();

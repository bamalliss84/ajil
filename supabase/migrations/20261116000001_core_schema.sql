-- =====================================================================
-- آجِل (Ajil) — المخطط الأساسي
-- PostgreSQL 15+ / Supabase
-- القواعد:
--   * كل جدول فيه store_id، والجداول التشغيلية فيها branch_id
--   * الحركات المالية سجل يُضاف فقط (لا تعديل ولا حذف)
--   * الأرصدة تُحسب من الحركات وتُخزَّن لكل (زبون، عملة)
-- =====================================================================

create schema if not exists app;

-- ---------------------------------------------------------------------
-- الباقات والاشتراكات
-- ---------------------------------------------------------------------
create table app.plans (
  code              text primary key,                 -- trial, basic, advanced, premium
  name_ar           text not null,
  customers_limit   int,                              -- null = غير محدود (لكل فرع)
  users_limit       int,                              -- null = غير محدود
  devices_limit     int,
  branches_included int not null default 1,
  monthly_price     numeric(14,2) not null default 0,
  price_currency    text not null default 'YER',
  is_active         boolean not null default true
);

-- ---------------------------------------------------------------------
-- المتاجر (البقالات) والفروع
-- ---------------------------------------------------------------------
create table app.stores (
  id                uuid primary key default gen_random_uuid(),
  name              text not null,
  owner_phone       text not null unique,             -- رقم جوال البقالة = رقم المالك (فريد في المنصة)
  country_code      text not null default 'YE',
  default_currency  text not null default 'YER',
  enabled_currencies text[] not null default array['YER','SAR'],
  status            text not null default 'active' check (status in ('active','suspended')),
  created_at        timestamptz not null default now()
);

create table app.branches (
  id          uuid primary key default gen_random_uuid(),
  store_id    uuid not null references app.stores(id),
  code        text not null,                          -- B1, B2 ... بادئة أرقام الفواتير
  name        text not null,
  is_active   boolean not null default true,
  created_at  timestamptz not null default now(),
  unique (store_id, code)
);

create table app.subscriptions (
  id            uuid primary key default gen_random_uuid(),
  store_id      uuid not null references app.stores(id),
  plan_code     text not null references app.plans(code),
  starts_at     timestamptz not null default now(),
  expires_at    timestamptz not null,
  extra_branches int not null default 0,
  activated_by  text,                                 -- من فعّل (مدير المنصة / كود تفعيل)
  payment_ref   text,
  created_at    timestamptz not null default now()
);
create index on app.subscriptions (store_id, expires_at desc);

-- تجربة مجانية مرة واحدة لكل رقم ولكل جهاز
create table app.trial_claims (
  phone        text primary key,
  device_key   text unique,
  claimed_at   timestamptz not null default now()
);

-- ---------------------------------------------------------------------
-- المستخدمون (المالك = 1، الموظفون 2، 3 ...)
-- ---------------------------------------------------------------------
create table app.app_users (
  id            uuid primary key default gen_random_uuid(),
  store_id      uuid not null references app.stores(id),
  user_no       int  not null check (user_no >= 1),
  auth_user_id  uuid unique,                          -- auth.users.id في Supabase
  display_name  text not null,
  role          text not null check (role in ('owner','employee')),
  is_active     boolean not null default true,
  created_at    timestamptz not null default now(),
  unique (store_id, user_no)
);
-- مالك واحد فقط لكل بقالة، وهو المستخدم رقم 1
create unique index app_users_one_owner on app.app_users (store_id) where role = 'owner';
alter table app.app_users add constraint owner_is_user_1 check (role <> 'owner' or user_no = 1);

create table app.user_branches (
  user_id    uuid not null references app.app_users(id),
  branch_id  uuid not null references app.branches(id),
  primary key (user_id, branch_id)
);

-- ---------------------------------------------------------------------
-- الأجهزة: الجهاز مرتبط ببقالة واحدة حتى يُلغى
-- ---------------------------------------------------------------------
create table app.devices (
  id            uuid primary key default gen_random_uuid(),
  store_id      uuid not null references app.stores(id),
  device_key    text not null,                        -- المفتاح العام المولّد في Android Keystore
  label         text,
  device_letter text not null,                        -- A, B ... لأرقام الفواتير
  approved      boolean not null default false,
  revoked_at    timestamptz,
  last_sync_at  timestamptz,
  created_at    timestamptz not null default now(),
  unique (store_id, device_letter)
);
-- لا يُستخدم نفس الجهاز في بقالتين إلا بعد إلغائه
create unique index devices_active_key on app.devices (device_key) where revoked_at is null;

-- ---------------------------------------------------------------------
-- الزبائن
-- ---------------------------------------------------------------------
create sequence app.sync_seq;                         -- مؤشر مزامنة عام يزيد مع كل تغيير

create table app.customers (
  id                uuid primary key,                 -- يولَّد في الجوال
  store_id          uuid not null references app.stores(id),
  branch_id         uuid not null references app.branches(id),
  name              text not null,
  phone             text,
  address           text,
  notes             text,
  default_currency  text not null,
  credit_limit      numeric(14,2),
  credit_limit_currency text,
  status            text not null default 'active' check (status in ('active','suspended','archived')),
  created_by        uuid references app.app_users(id),
  created_at        timestamptz not null default now(),
  updated_at        timestamptz not null default now(),
  server_seq        bigint not null default nextval('app.sync_seq')
);
create index on app.customers (store_id, branch_id, server_seq);
create index on app.customers (store_id, branch_id, phone);

-- ---------------------------------------------------------------------
-- الحركات المالية (سجل يُضاف فقط)
-- ---------------------------------------------------------------------
create table app.transactions (
  id              uuid primary key,                   -- يولَّد في الجوال (منع التكرار)
  store_id        uuid not null references app.stores(id),
  branch_id       uuid not null references app.branches(id),
  customer_id     uuid not null references app.customers(id),
  kind            text not null check (kind in
                    ('opening','debt','payment','payment_fx','return','discount','void')),
  amount          numeric(14,2) not null check (amount > 0),
  currency        text not null,
  signed_amount   numeric(14,2) not null,             -- يحسبه الخادم: + يزيد الدين، − ينقصه
  -- سداد بعملة مختلفة: ما دفعه الزبون فعلاً وسعر الصرف المتفق عليه
  fx_paid_amount  numeric(14,2),
  fx_paid_currency text,
  fx_rate         numeric(18,6),
  voided_id       uuid references app.transactions(id),
  void_reason     text,
  description     text,
  invoice_no      text,
  due_date        date,                               -- موعد السداد (اختياري)
  created_by      uuid not null references app.app_users(id),
  device_id       uuid references app.devices(id),
  device_seq      bigint,                             -- تسلسل الجوال 1، 2، 3 ...
  created_at      timestamptz not null,               -- وقت الجوال (للعرض)
  received_at     timestamptz not null default now(), -- وقت الخادم (المرجع)
  server_seq      bigint not null default nextval('app.sync_seq'),
  prev_hash       text,
  hash            text,
  constraint void_needs_ref   check ((kind = 'void') = (voided_id is not null)),
  constraint fx_fields        check (kind <> 'payment_fx' or
                                     (fx_paid_amount > 0 and fx_paid_currency is not null and fx_rate > 0)),
  unique (device_id, device_seq)
);
-- الحركة لا تُلغى مرتين
create unique index transactions_single_void on app.transactions (voided_id) where kind = 'void';
create index on app.transactions (store_id, branch_id, server_seq);
create index on app.transactions (store_id, customer_id, created_at desc);

-- الرصيد المخزّن: صف لكل (زبون، عملة)
create table app.customer_balances (
  customer_id  uuid not null references app.customers(id),
  currency     text not null,
  store_id     uuid not null,
  branch_id    uuid not null,
  balance      numeric(14,2) not null default 0,
  total_debit  numeric(14,2) not null default 0,       -- مجموع ما زاد الدين
  total_credit numeric(14,2) not null default 0,       -- مجموع ما أنقص الدين
  last_tx_at   timestamptz,
  primary key (customer_id, currency)
);

-- ---------------------------------------------------------------------
-- وعود السداد (ليست حركة مالية)
-- ---------------------------------------------------------------------
create table app.promises (
  id            uuid primary key,
  store_id      uuid not null references app.stores(id),
  branch_id     uuid not null references app.branches(id),
  customer_id   uuid not null references app.customers(id),
  promised_date date not null,
  amount        numeric(14,2),
  currency      text,
  note          text,
  remind_day_before boolean not null default false,
  remind_customer   boolean not null default false,
  status        text not null default 'open' check (status in ('open','kept','cancelled')),
  created_by    uuid references app.app_users(id),
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now(),
  server_seq    bigint not null default nextval('app.sync_seq')
);
create index on app.promises (store_id, branch_id, server_seq);

-- إعدادات التنبيهات لكل بقالة
create table app.store_settings (
  store_id                uuid primary key references app.stores(id),
  monthly_claim_enabled   boolean not null default true,
  monthly_claim_day       int not null default 1 check (monthly_claim_day between 0 and 28), -- 0 = آخر يوم
  monthly_claim_time      time not null default '09:00',
  monthly_claim_min       numeric(14,2) not null default 1000,
  overdue_days            int not null default 30,
  employee_void_hours     int not null default 24,
  reminder_template       text not null default
    'السلام عليكم {الاسم}، نذكّرك بأن رصيدك لدى {البقالة} هو {المبلغ}. كشف حسابك: {الرابط}. شكراً لتعاملك معنا.',
  updated_at              timestamptz not null default now()
);

-- ---------------------------------------------------------------------
-- سجل التدقيق
-- ---------------------------------------------------------------------
create table app.audit_log (
  id          bigint generated always as identity primary key,
  store_id    uuid,
  table_name  text not null,
  row_id      uuid,
  action      text not null,
  old_data    jsonb,
  new_data    jsonb,
  actor       uuid,
  at          timestamptz not null default now()
);
create index on app.audit_log (store_id, at desc);

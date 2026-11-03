-- NOVA BAT: çok şirketli (multi-tenant) temel şema. Her tablo company_id taşır, RLS ile korunur.

create extension if not exists pgcrypto;

create table public.companies (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  siret text, tva_number text, address text, email text, phone text,
  logo_url text,
  invoice_prefix text not null default 'FA',
  default_lang text not null default 'fr',
  created_at timestamptz not null default now()
);

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text, photo_url text,
  lang text not null default 'fr',
  created_at timestamptz not null default now()
);

create type public.member_role as enum ('admin','manager','site_lead','accountant','worker');

create table public.memberships (
  company_id uuid not null references public.companies(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role public.member_role not null default 'worker',
  created_at timestamptz not null default now(),
  primary key (company_id, user_id)
);
create index on public.memberships(user_id);

create table public.invitations (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  email text not null,
  role public.member_role not null default 'worker',
  token uuid not null default gen_random_uuid() unique,
  accepted_at timestamptz,
  created_at timestamptz not null default now()
);

-- Yardımcı fonksiyonlar (RLS içinde özyineleme olmaması için security definer)
create or replace function public.is_member(cid uuid) returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from memberships where company_id = cid and user_id = auth.uid());
$$;
create or replace function public.has_role(cid uuid, roles public.member_role[]) returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from memberships where company_id = cid and user_id = auth.uid() and role = any(roles));
$$;

-- Şirket oluşturma: oluşturan kişi otomatik admin olur
create or replace function public.create_company(p_name text) returns uuid
language plpgsql security definer set search_path = public as $$
declare cid uuid;
begin
  if auth.uid() is null then raise exception 'not authenticated'; end if;
  insert into companies(name) values (p_name) returning id into cid;
  insert into memberships(company_id, user_id, role) values (cid, auth.uid(), 'admin');
  return cid;
end $$;

-- Müşteriler (birden fazla e-posta)
create table public.customers (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  name text not null, siret text, tva_number text, address text, phone text,
  emails text[] not null default '{}',
  created_at timestamptz not null default now()
);

create table public.products (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  name text not null, unit text not null default 'u',
  unit_price numeric(12,2) not null default 0,
  vat_rate numeric(5,2) not null default 20,
  active boolean not null default true,
  created_at timestamptz not null default now()
);

-- Ayarlardan tanımlanan kategoriler (işçi tipi, kiralık ekipman, malzeme)
create type public.category_kind as enum ('worker','rental','purchase');
create table public.categories (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  kind public.category_kind not null,
  name text not null,
  default_unit_cost numeric(12,2),
  unique (company_id, kind, name)
);

-- Şantiyeler: otomatik numara CH-YYYY-NNN (şirket bazında)
create table public.sites (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  number text,
  name text not null,
  customer_id uuid references public.customers(id) on delete set null,
  address text, budget numeric(14,2),
  status text not null default 'active',
  start_date date, end_date date,
  created_at timestamptz not null default now(),
  unique (company_id, number)
);
create or replace function public.sites_set_number() returns trigger
language plpgsql as $$
declare n int; y text := to_char(now(),'YYYY');
begin
  if new.number is null then
    perform pg_advisory_xact_lock(hashtext(new.company_id::text || y));
    select count(*)+1 into n from sites where company_id = new.company_id and number like 'CH-'||y||'-%';
    new.number := 'CH-'||y||'-'||lpad(n::text,3,'0');
  end if;
  return new;
end $$;
create trigger sites_number before insert on public.sites for each row execute function public.sites_set_number();

-- İşçiler (uygulama kullanıcısı olmak zorunda değil)
create table public.workers (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  full_name text not null, photo_url text, phone text,
  category_id uuid references public.categories(id) on delete set null,
  hourly_cost numeric(10,2),
  user_id uuid references auth.users(id) on delete set null,
  active boolean not null default true
);

-- Puantaj
create type public.time_kind as enum ('normal','overtime','weather','absence');
create table public.time_entries (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  site_id uuid not null references public.sites(id) on delete cascade,
  worker_id uuid not null references public.workers(id) on delete cascade,
  work_date date not null,
  hours numeric(4,2) not null default 0,
  kind public.time_kind not null default 'normal',
  note text,
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now()
);
create index on public.time_entries(site_id, work_date);

-- Şantiye kiralamaları ve satın almaları
create table public.site_rentals (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  site_id uuid not null references public.sites(id) on delete cascade,
  category_id uuid references public.categories(id) on delete set null,
  description text, supplier text,
  start_date date, return_date date,
  daily_cost numeric(12,2),
  created_at timestamptz not null default now()
);
create table public.site_purchases (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  site_id uuid not null references public.sites(id) on delete cascade,
  category_id uuid references public.categories(id) on delete set null,
  description text, supplier text,
  quantity numeric(12,2) not null default 1, unit text,
  unit_cost numeric(12,2) not null default 0,
  purchase_date date not null default current_date,
  created_at timestamptz not null default now()
);

-- Bon de commande ve fatura (aynı yapı, satırlar ayrı tabloda)
create type public.doc_kind as enum ('quote','order','invoice');
create table public.documents (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  kind public.doc_kind not null,
  number text,
  customer_id uuid references public.customers(id) on delete restrict,
  site_id uuid references public.sites(id) on delete set null,
  source_id uuid references public.documents(id) on delete set null,
  issue_date date not null default current_date,
  due_date date,
  status text not null default 'draft',
  sent_to text[] not null default '{}',
  sent_at timestamptz,
  total_ht numeric(14,2) not null default 0,
  total_tva numeric(14,2) not null default 0,
  total_ttc numeric(14,2) not null default 0,
  pdf_path text,
  einvoice_status text,
  notes text,
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now(),
  unique (company_id, kind, number)
);
create table public.document_lines (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  document_id uuid not null references public.documents(id) on delete cascade,
  position int not null default 0,
  product_id uuid references public.products(id) on delete set null,
  label text not null, unit text,
  quantity numeric(12,2) not null default 1,
  unit_price numeric(12,2) not null default 0,
  vat_rate numeric(5,2) not null default 20
);

-- RLS
alter table public.companies enable row level security;
alter table public.profiles enable row level security;
alter table public.memberships enable row level security;
alter table public.invitations enable row level security;

create policy "members read company" on public.companies for select using (public.is_member(id));
create policy "admins update company" on public.companies for update using (public.has_role(id, array['admin']::public.member_role[]));

create policy "own profile" on public.profiles for all using (id = auth.uid()) with check (id = auth.uid());
create policy "colleagues read profiles" on public.profiles for select using (
  exists (select 1 from public.memberships m1 join public.memberships m2 on m1.company_id = m2.company_id
          where m1.user_id = auth.uid() and m2.user_id = profiles.id));

create policy "members read memberships" on public.memberships for select using (public.is_member(company_id));
create policy "admins manage memberships" on public.memberships for all
  using (public.has_role(company_id, array['admin']::public.member_role[]))
  with check (public.has_role(company_id, array['admin']::public.member_role[]));

create policy "admins manage invitations" on public.invitations for all
  using (public.has_role(company_id, array['admin']::public.member_role[]))
  with check (public.has_role(company_id, array['admin']::public.member_role[]));

do $$
declare t text;
begin
  foreach t in array array['customers','products','categories','sites','workers','time_entries',
                           'site_rentals','site_purchases','documents','document_lines'] loop
    execute format('alter table public.%I enable row level security', t);
    execute format('create policy "members all" on public.%I for all using (public.is_member(company_id)) with check (public.is_member(company_id))', t);
    execute format('create index on public.%I(company_id)', t);
  end loop;
end $$;

-- Yeni kullanıcıya profil
create or replace function public.handle_new_user() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  insert into profiles(id, full_name) values (new.id, new.raw_user_meta_data->>'full_name') on conflict do nothing;
  return new;
end $$;
create trigger on_auth_user_created after insert on auth.users for each row execute function public.handle_new_user();

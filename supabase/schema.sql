-- NOVADA Phase 1 schema. Run in Supabase SQL Editor.
create extension if not exists pgcrypto;
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null default '',
  role text not null default 'operator' check (role in ('admin','director','workshop_manager','planner','warehouse','team_lead','operator','qc','accountant')),
  created_at timestamptz not null default now()
);
create table if not exists public.customers (
  id uuid primary key default gen_random_uuid(), code text unique, name text not null,
  phone text, address text, created_at timestamptz not null default now()
);
create table if not exists public.orders (
  id uuid primary key default gen_random_uuid(), code text not null unique,
  customer_id uuid references public.customers(id), customer_name text not null,
  received_date date not null default current_date, due_date date,
  status text not null default 'Chờ xác nhận' check(status in ('Mới tiếp nhận','Chờ xác nhận','Đã xác nhận','Chờ lập kế hoạch','Chờ sản xuất','Đang sản xuất','Chờ kiểm tra','Hoàn thành','Đã giao hàng','Đã hủy')),
  total_quantity numeric(14,3) not null default 0 check(total_quantity>=0), note text,
  created_by uuid references auth.users(id), created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create index if not exists orders_status_due_idx on public.orders(status,due_date);
create table if not exists public.materials (
  id uuid primary key default gen_random_uuid(), code text not null unique, name text not null,
  category text not null, unit text not null, stock numeric(14,3) not null default 0 check(stock>=0),
  min_stock numeric(14,3) not null default 0 check(min_stock>=0), unit_weight numeric(12,4), color text,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.warehouses (
  id uuid primary key default gen_random_uuid(), code text not null unique, name text not null,
  address text, is_active boolean not null default true
);
create table if not exists public.inventory_transactions (
  id uuid primary key default gen_random_uuid(), material_id uuid not null references public.materials(id),
  warehouse_id uuid references public.warehouses(id), transaction_type text not null check(transaction_type in ('IN','OUT','ADJUST')),
  quantity numeric(14,3) not null check(quantity>0), reference_code text, note text,
  created_by uuid references auth.users(id), created_at timestamptz not null default now()
);
create index if not exists inventory_tx_material_date_idx on public.inventory_transactions(material_id,created_at desc);
create or replace function public.apply_inventory_transaction() returns trigger language plpgsql security definer set search_path=public as $$
begin
  if new.transaction_type='IN' then update public.materials set stock=stock+new.quantity,updated_at=now() where id=new.material_id;
  elsif new.transaction_type='OUT' then
    update public.materials set stock=stock-new.quantity,updated_at=now() where id=new.material_id and stock>=new.quantity;
    if not found then raise exception 'Insufficient inventory for material %',new.material_id; end if;
  else raise exception 'ADJUST requires an approved adjustment workflow'; end if;
  return new;
end; $$;
drop trigger if exists inventory_transaction_apply on public.inventory_transactions;
create trigger inventory_transaction_apply before insert on public.inventory_transactions for each row execute function public.apply_inventory_transaction();
create or replace function public.set_updated_at() returns trigger language plpgsql as $$ begin new.updated_at=now(); return new; end; $$;
drop trigger if exists orders_updated_at on public.orders;
create trigger orders_updated_at before update on public.orders for each row execute function public.set_updated_at();
drop trigger if exists materials_updated_at on public.materials;
create trigger materials_updated_at before update on public.materials for each row execute function public.set_updated_at();
-- Initial warehouse
insert into public.warehouses(code,name) values('KHO-CHINH','Kho chính') on conflict(code) do nothing;
-- RLS: authenticated users can read; writes are restricted to authenticated users.
alter table public.profiles enable row level security;
alter table public.customers enable row level security;
alter table public.orders enable row level security;
alter table public.materials enable row level security;
alter table public.warehouses enable row level security;
alter table public.inventory_transactions enable row level security;
do $$ declare t text; begin
 foreach t in array array['customers','orders','materials','warehouses','inventory_transactions'] loop
  execute format('drop policy if exists %I on public.%I',t||'_authenticated_all',t);
  execute format('create policy %I on public.%I for all to authenticated using (true) with check (true)',t||'_authenticated_all',t);
 end loop;
end $$;
drop policy if exists profiles_self_read on public.profiles;
create policy profiles_self_read on public.profiles for select to authenticated using (id=auth.uid());
-- Add a profile when a new Auth user is created.
create or replace function public.handle_new_user() returns trigger language plpgsql security definer set search_path=public as $$
begin insert into public.profiles(id,full_name) values(new.id,coalesce(new.raw_user_meta_data->>'full_name','')); return new; end; $$;
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users for each row execute procedure public.handle_new_user();

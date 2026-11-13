-- NOVADA Phase 2: Kế hoạch sản xuất cho xưởng gia công cửa nhôm
-- Chạy một lần trong Supabase SQL Editor sau khi đã cài schema.sql Phase 1.

create table if not exists public.production_plans (
  id uuid primary key default gen_random_uuid(),
  plan_code text not null unique,
  order_id uuid not null references public.orders(id) on delete restrict,
  order_code text not null,
  customer_name text not null,
  planned_date date not null,
  quantity numeric(14,2) not null check (quantity > 0),
  priority text not null default 'Bình thường'
    check (priority in ('Bình thường','Cao','Khẩn cấp')),
  status text not null default 'Chờ triển khai'
    check (status in ('Chờ triển khai','Đang thực hiện','Tạm dừng','Hoàn thành','Đã hủy')),
  note text,
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists production_plans_order_idx
  on public.production_plans(order_id);
create index if not exists production_plans_date_idx
  on public.production_plans(planned_date);

create or replace function public.set_production_plan_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists production_plans_updated_at on public.production_plans;
create trigger production_plans_updated_at
before update on public.production_plans
for each row execute function public.set_production_plan_updated_at();

alter table public.production_plans enable row level security;
drop policy if exists production_plans_authenticated_all on public.production_plans;
create policy production_plans_authenticated_all
on public.production_plans for all to authenticated
using (true) with check (true);

-- NOVADA Phase 2.1: Lệnh sản xuất và tiến độ gia công cửa nhôm
-- Chạy sau phase2_planning.sql trong Supabase SQL Editor.
create table if not exists public.production_jobs (
 id uuid primary key default gen_random_uuid(), job_code text not null unique,
 plan_id uuid not null unique references public.production_plans(id) on delete restrict,
 plan_code text not null, order_code text not null, customer_name text not null,
 target_quantity numeric(14,2) not null check(target_quantity > 0),
 completed_quantity numeric(14,2) not null default 0 check(completed_quantity >= 0),
 rejected_quantity numeric(14,2) not null default 0 check(rejected_quantity >= 0),
 current_stage text not null default 'Cắt nhôm',
 status text not null default 'Chờ sản xuất' check(status in ('Chờ sản xuất','Đang sản xuất','Tạm dừng','Hoàn thành')),
 started_at timestamptz, note text, created_by uuid references auth.users(id),
 created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
 constraint production_job_qty_check check(completed_quantity + rejected_quantity <= target_quantity)
);
create index if not exists production_jobs_plan_idx on public.production_jobs(plan_id);
create index if not exists production_jobs_status_idx on public.production_jobs(status);
create or replace function public.set_production_job_updated_at() returns trigger language plpgsql as $$ begin new.updated_at=now(); return new; end; $$;
drop trigger if exists production_jobs_updated_at on public.production_jobs;
create trigger production_jobs_updated_at before update on public.production_jobs for each row execute function public.set_production_job_updated_at();
alter table public.production_jobs enable row level security;
drop policy if exists production_jobs_authenticated_all on public.production_jobs;
create policy production_jobs_authenticated_all on public.production_jobs for all to authenticated using(true) with check(true);

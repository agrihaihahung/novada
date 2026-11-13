-- NOVADA Phase 2.2: Nhật ký công đoạn sản xuất
-- Chạy sau phase2_1_production.sql.
create table if not exists public.production_operations (
 id uuid primary key default gen_random_uuid(),
 job_id uuid not null references public.production_jobs(id) on delete restrict,
 job_code text not null,
 stage text not null check(stage in ('Cắt nhôm','Phay / khoan','Ép góc & lắp ráp','Lắp kính & phụ kiện','Kiểm tra QC','Đóng gói')),
 team_name text,
 machine_name text,
 good_quantity numeric(14,2) not null default 0 check(good_quantity >= 0),
 reject_quantity numeric(14,2) not null default 0 check(reject_quantity >= 0),
 work_date date not null default current_date,
 note text,
 created_by uuid references auth.users(id),
 created_at timestamptz not null default now(),
 constraint production_operation_qty_check check(good_quantity + reject_quantity > 0)
);
create index if not exists production_operations_job_idx on public.production_operations(job_id);
create index if not exists production_operations_date_idx on public.production_operations(work_date desc);
alter table public.production_operations enable row level security;
drop policy if exists production_operations_authenticated_all on public.production_operations;
create policy production_operations_authenticated_all on public.production_operations
for all to authenticated using(true) with check(true);

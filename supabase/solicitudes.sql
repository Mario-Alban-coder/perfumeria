-- =====================================================================
-- Solicitudes de registro de vendedores (el dueño las aprueba en la app)
-- Pega TODO este archivo en Supabase → SQL Editor → Run
-- =====================================================================
create table if not exists public.solicitudes (
  id      uuid primary key references auth.users(id) on delete cascade,
  nombre  text not null,
  usuario text not null,
  fecha   timestamptz not null default now()
);

alter table public.solicitudes enable row level security;

drop policy if exists solicitudes_insert on public.solicitudes;
drop policy if exists solicitudes_select on public.solicitudes;
drop policy if exists solicitudes_delete on public.solicitudes;
create policy solicitudes_insert on public.solicitudes for insert to authenticated with check (id = auth.uid());
create policy solicitudes_select on public.solicitudes for select to authenticated using (id = auth.uid() or public.is_admin());
create policy solicitudes_delete on public.solicitudes for delete to authenticated using (id = auth.uid() or public.is_admin());

grant select, insert, delete on public.solicitudes to authenticated;

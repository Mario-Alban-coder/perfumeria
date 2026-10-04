-- =====================================================================
-- Permite ventas SIN indicar el perfume (solo tamaño). El control de stock
-- sigue funcionando: por perfume cuando se indica, y siempre por tamaño total.
-- Pega TODO este archivo en Supabase → SQL Editor → Run
-- =====================================================================
create or replace function public.validar_stock() returns trigger
language plpgsql security definer set search_path = public as $$
declare r record; tengo int;
begin
  -- 1) Por perfume y tamaño (solo los ítems en los que se indicó el perfume)
  for r in
    select it->>'pid' as pid, (it->>'ml')::int as ml, sum((it->>'cant')::int)::int as necesito
    from jsonb_array_elements(new.items) as it
    where coalesce(it->>'pid', '') <> ''
    group by 1, 2
  loop
    select coalesce((select sum(case when e.tipo = 'devolucion' then -(x->>'cant')::int else (x->>'cant')::int end)
                     from public.entregas e, jsonb_array_elements(e.items) as x
                     where e.vid = new.vid and x->>'pid' = r.pid and (x->>'ml')::int = r.ml), 0)
         - coalesce((select sum((y->>'cant')::int)
                     from public.ventas v, jsonb_array_elements(v.items) as y
                     where v.vid = new.vid and v.id <> new.id and y->>'pid' = r.pid and (y->>'ml')::int = r.ml), 0)
    into tengo;
    if tengo < r.necesito then
      raise exception 'No tienes suficiente de ese perfume en % ml (te quedan %, intentas vender %).', r.ml, tengo, r.necesito;
    end if;
  end loop;

  -- 2) Total por tamaño (incluye las ventas sin perfume indicado)
  for r in
    select (it->>'ml')::int as ml, sum((it->>'cant')::int)::int as necesito
    from jsonb_array_elements(new.items) as it
    group by 1
  loop
    select coalesce((select sum(case when e.tipo = 'devolucion' then -(x->>'cant')::int else (x->>'cant')::int end)
                     from public.entregas e, jsonb_array_elements(e.items) as x
                     where e.vid = new.vid and (x->>'ml')::int = r.ml), 0)
         - coalesce((select sum((y->>'cant')::int)
                     from public.ventas v, jsonb_array_elements(v.items) as y
                     where v.vid = new.vid and v.id <> new.id and (y->>'ml')::int = r.ml), 0)
    into tengo;
    if tengo < r.necesito then
      raise exception 'No tienes suficientes frascos de % ml (te quedan %, intentas vender %).', r.ml, tengo, r.necesito;
    end if;
  end loop;
  return new;
end $$;

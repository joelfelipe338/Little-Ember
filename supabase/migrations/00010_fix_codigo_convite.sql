-- =====================================================================
-- CHAMMA · 00010 · Corrige criação de usuário (anônimo e cadastro)
--
-- O default de profiles.codigo_convite chama gerar_codigo_convite(),
-- que procurava "profiles" sem schema. O Auth do Supabase cria usuários
-- com search_path = auth, então dava:
--   "Database error creating anonymous user" / "creating new user".
-- =====================================================================

create or replace function public.gerar_codigo_convite() returns text
language plpgsql volatile security definer set search_path = public as $$
declare
  alfabeto text := 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; -- sem 0/O e 1/I
  codigo text;
begin
  loop
    codigo := '';
    for i in 1..6 loop
      codigo := codigo || substr(alfabeto, 1 + floor(random() * length(alfabeto))::int, 1);
    end loop;
    exit when not exists (select 1 from public.profiles where codigo_convite = codigo);
  end loop;
  return codigo;
end $$;

-- Mesmo cuidado no trigger de plano (roda em updates de profiles).
create or replace function public.proteger_plano() returns trigger
language plpgsql set search_path = public as $$
begin
  if (new.plano is distinct from old.plano or new.plano_expira_em is distinct from old.plano_expira_em)
     and coalesce(auth.role(), '') in ('authenticated', 'anon') then
    raise exception 'plano_protegido';
  end if;
  return new;
end $$;

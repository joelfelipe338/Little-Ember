-- =====================================================================
-- CHAMMA · 00009 · Local no mapa + assinatura (CHAMMA+)
-- =====================================================================

-- ------------------------------------------------------------- local no mapa
alter table places add column if not exists latitude double precision;
alter table places add column if not exists longitude double precision;

-- O local de um rolê aparece pra qualquer pessoa com o link (inclusive no navegador).
drop policy if exists "Local de rolê é público" on places;
create policy "Local de rolê é público" on places for select using (
  exists (select 1 from plans p where p.lugar_final_id = places.id)
);

-- ------------------------------------------------------------- assinatura
-- Para testar: no Table Editor, mude profiles.plano do seu usuário para 'plus'
-- (e deixe plano_expira_em vazio, ou com uma data no futuro).
alter table profiles add column if not exists plano text not null default 'gratis';
alter table profiles add column if not exists plano_expira_em timestamptz;
do $$ begin
  alter table profiles add constraint chk_plano check (plano in ('gratis', 'plus'));
exception when duplicate_object then null;
end $$;

-- Limites de cada plano. Dá pra mudar os números direto nesta tabela.
create table if not exists plan_limits (
  plano text not null check (plano in ('gratis', 'plus')),
  recurso text not null,
  valor int not null,
  primary key (plano, recurso)
);

insert into plan_limits (plano, recurso, valor) values
  ('gratis', 'roles_ativos', 3),        -- rolês em votação ao mesmo tempo
  ('gratis', 'horarios_por_role', 5),   -- opções de horário por rolê
  ('gratis', 'pessoas_por_role', 15),   -- convidados por rolê
  ('gratis', 'grupos', 3),              -- grupos de conexões
  ('gratis', 'modos_avancados', 0),     -- Rápido / Secreto (fecha sozinho, voto secreto, limite de "Posso")
  ('plus',   'roles_ativos', 1000),
  ('plus',   'horarios_por_role', 15),
  ('plus',   'pessoas_por_role', 200),
  ('plus',   'grupos', 1000),
  ('plus',   'modos_avancados', 1)
on conflict (plano, recurso) do nothing;

alter table plan_limits enable row level security;
drop policy if exists "Limites são públicos" on plan_limits;
create policy "Limites são públicos" on plan_limits for select using (true);

-- Plano valendo agora (plus vencido volta a ser grátis).
create or replace function plano_efetivo(p_user uuid) returns text
language sql stable security definer set search_path = public as $$
  select case
    when p.plano = 'plus' and (p.plano_expira_em is null or p.plano_expira_em > now()) then 'plus'
    else 'gratis'
  end
  from profiles p where p.id = p_user
$$;

create or replace function limite_do_plano(p_user uuid, p_recurso text) returns int
language sql stable security definer set search_path = public as $$
  select coalesce(
    (select valor from plan_limits where plano = coalesce(plano_efetivo(p_user), 'gratis') and recurso = p_recurso),
    0
  )
$$;

grant execute on function plano_efetivo(uuid) to anon, authenticated;
grant execute on function limite_do_plano(uuid, text) to anon, authenticated;

-- O próprio usuário não pode se dar o plano (só o painel / servidor).
create or replace function proteger_plano() returns trigger
language plpgsql as $$
begin
  if (new.plano is distinct from old.plano or new.plano_expira_em is distinct from old.plano_expira_em)
     and coalesce(auth.role(), '') in ('authenticated', 'anon') then
    raise exception 'plano_protegido';
  end if;
  return new;
end $$;

drop trigger if exists trg_proteger_plano on profiles;
create trigger trg_proteger_plano before update on profiles
  for each row execute function proteger_plano();

-- ------------------------------------------------------------- limites no banco
-- Rolês em votação ao mesmo tempo + modos avançados.
create or replace function checar_limites_plano() returns trigger
language plpgsql security definer set search_path = public as $$
declare
  ativos int;
begin
  if tg_op = 'INSERT' then
    select count(*) into ativos from plans
    where criador_id = new.criador_id and status = 'votando' and prazo_votacao > now();
    if ativos >= limite_do_plano(new.criador_id, 'roles_ativos') then
      raise exception 'limite_roles_ativos';
    end if;
  end if;

  if (new.auto_fechar or new.voto_anonimo or new.limite_posso > 0)
     and limite_do_plano(new.criador_id, 'modos_avancados') = 0
     and (tg_op = 'INSERT'
          or new.auto_fechar is distinct from old.auto_fechar
          or new.voto_anonimo is distinct from old.voto_anonimo
          or new.limite_posso is distinct from old.limite_posso) then
    raise exception 'recurso_plus';
  end if;
  return new;
end $$;

drop trigger if exists trg_limites_plano on plans;
create trigger trg_limites_plano before insert or update on plans
  for each row execute function checar_limites_plano();

-- Horários por rolê (vale também pras sugestões da galera).
create or replace function checar_limite_horarios() returns trigger
language plpgsql security definer set search_path = public as $$
declare
  dono uuid;
  total int;
begin
  select criador_id into dono from plans where id = new.plan_id;
  select count(*) into total from time_options where plan_id = new.plan_id;
  if total >= limite_do_plano(dono, 'horarios_por_role') then
    raise exception 'limite_horarios';
  end if;
  return new;
end $$;

drop trigger if exists trg_limite_horarios on time_options;
create trigger trg_limite_horarios before insert on time_options
  for each row execute function checar_limite_horarios();

-- Pessoas por rolê (convidados; o organizador não conta).
create or replace function checar_limite_pessoas() returns trigger
language plpgsql security definer set search_path = public as $$
declare
  dono uuid;
  total int;
begin
  if new.papel <> 'convidado' then return new; end if;
  select criador_id into dono from plans where id = new.plan_id;
  select count(*) into total from plan_members where plan_id = new.plan_id and papel = 'convidado';
  if total >= limite_do_plano(dono, 'pessoas_por_role') then
    raise exception 'limite_pessoas';
  end if;
  return new;
end $$;

drop trigger if exists trg_limite_pessoas on plan_members;
create trigger trg_limite_pessoas before insert on plan_members
  for each row execute function checar_limite_pessoas();

-- Grupos de conexões.
create or replace function checar_limite_grupos() returns trigger
language plpgsql security definer set search_path = public as $$
declare
  total int;
begin
  select count(*) into total from contact_groups where criado_por = new.criado_por;
  if total >= limite_do_plano(new.criado_por, 'grupos') then
    raise exception 'limite_grupos';
  end if;
  return new;
end $$;

drop trigger if exists trg_limite_grupos on contact_groups;
create trigger trg_limite_grupos before insert on contact_groups
  for each row execute function checar_limite_grupos();

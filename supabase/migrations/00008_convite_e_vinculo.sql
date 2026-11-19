-- =====================================================================
-- CHAMMA · 00008 · Código de convite + vínculo de conexões
--
-- 1) Todo usuário ganha um código de convite (6 letras/números).
-- 2) Vínculo: quem tem o app abre o link do rolê, escolhe o próprio nome
--    e pede pra vincular. Quem organizou aceita, e a conexão que ele
--    criou vira uma conexão real (as duas pessoas no app). A partir daí,
--    ao chamar essa conexão num rolê, o rolê aparece direto no app dela.
-- =====================================================================

-- ------------------------------------------------------------- código de convite
create or replace function gerar_codigo_convite() returns text
language plpgsql volatile as $$
declare
  alfabeto text := 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; -- sem 0/O e 1/I
  codigo text;
begin
  loop
    codigo := '';
    for i in 1..6 loop
      codigo := codigo || substr(alfabeto, 1 + floor(random() * length(alfabeto))::int, 1);
    end loop;
    exit when not exists (select 1 from profiles where codigo_convite = codigo);
  end loop;
  return codigo;
end $$;

alter table profiles add column if not exists codigo_convite text;
update profiles set codigo_convite = gerar_codigo_convite() where codigo_convite is null;
alter table profiles alter column codigo_convite set default gerar_codigo_convite();
create unique index if not exists profiles_codigo_convite_uniq on profiles(codigo_convite);

-- ------------------------------------------------------------- conexão real
-- Conexão ligada a um usuário de verdade do app.
alter table connections
  add column if not exists linked_user_id uuid references profiles(id) on delete set null;

create unique index if not exists connections_owner_linked_uniq
  on connections(criado_por, linked_user_id)
  where linked_user_id is not null;

-- Organizador pode pôr no rolê, já com user_id, uma conexão vinculada.
-- (O rolê aparece direto na lista de rolês da outra pessoa.)
drop policy if exists "Organizador adiciona conexão vinculada" on plan_members;
create policy "Organizador adiciona conexão vinculada" on plan_members for insert with check (
  papel = 'convidado'
  and user_id is not null
  and connection_id is not null
  and exists (select 1 from plans p where p.id = plan_id and p.criador_id = auth.uid())
  and exists (
    select 1 from connections c
    where c.id = connection_id and c.criado_por = auth.uid() and c.linked_user_id = user_id
  )
);

-- ------------------------------------------------------------- pedidos de vínculo
create table if not exists link_requests (
  id uuid primary key default gen_random_uuid(),
  connection_id uuid not null references connections(id) on delete cascade,
  owner_id uuid not null references profiles(id) on delete cascade,     -- quem criou a conexão
  requester_id uuid not null references profiles(id) on delete cascade, -- quem pediu o vínculo
  plan_id uuid references plans(id) on delete set null,                 -- rolê de onde veio o pedido
  status text not null default 'pendente' check (status in ('pendente', 'aceito', 'recusado')),
  created_at timestamptz not null default now(),
  responded_at timestamptz
);

create unique index if not exists link_requests_pendente_uniq
  on link_requests(connection_id, requester_id)
  where status = 'pendente';
create index if not exists idx_link_requests_owner on link_requests(owner_id, status);

alter table link_requests enable row level security;
drop policy if exists "Partes veem o pedido" on link_requests;
create policy "Partes veem o pedido" on link_requests for select
  using (auth.uid() = owner_id or auth.uid() = requester_id);
-- Sem insert/update direto: só pelas funções abaixo.

do $$ begin
  alter publication supabase_realtime add table link_requests;
exception when duplicate_object then null;
end $$;

-- Pede o vínculo a partir da vaga que a pessoa ocupa no rolê.
create or replace function request_link(p_member_id uuid) returns text
language plpgsql security definer set search_path = public as $$
declare
  eu uuid := auth.uid();
  m plan_members;
  c connections;
begin
  if eu is null then raise exception 'sem_login'; end if;
  if exists (select 1 from auth.users u where u.id = eu and coalesce(u.is_anonymous, false)) then
    raise exception 'conta_anonima';
  end if;

  select * into m from plan_members where id = p_member_id;
  if m.id is null or m.user_id is distinct from eu then raise exception 'vaga_de_outra_pessoa'; end if;
  if m.connection_id is null then raise exception 'sem_conexao'; end if;

  select * into c from connections where id = m.connection_id;
  if c.id is null then raise exception 'sem_conexao'; end if;
  if c.criado_por = eu then raise exception 'propria_conexao'; end if;
  if c.linked_user_id = eu then return 'aceito'; end if;
  if c.linked_user_id is not null then raise exception 'ja_vinculada'; end if;

  if not exists (
    select 1 from link_requests
    where connection_id = c.id and requester_id = eu and status = 'pendente'
  ) then
    insert into link_requests (connection_id, owner_id, requester_id, plan_id)
    values (c.id, c.criado_por, eu, m.plan_id);
  end if;
  return 'pendente';
end $$;

-- Quem criou a conexão aceita ou recusa.
create or replace function respond_link(p_request_id uuid, p_accept boolean) returns void
language plpgsql security definer set search_path = public as $$
declare
  eu uuid := auth.uid();
  r link_requests;
  tipo_conexao connection_type;
  meu_nome text;
begin
  select * into r from link_requests where id = p_request_id and owner_id = eu and status = 'pendente';
  if r.id is null then raise exception 'pedido_nao_encontrado'; end if;

  if not p_accept then
    update link_requests set status = 'recusado', responded_at = now() where id = r.id;
    return;
  end if;

  -- A conexão que eu criei passa a apontar pra pessoa real.
  update connections set linked_user_id = r.requester_id where id = r.connection_id
  returning tipo into tipo_conexao;

  -- E a outra pessoa ganha uma conexão comigo (se ainda não tiver).
  if not exists (
    select 1 from connections where criado_por = r.requester_id and linked_user_id = eu
  ) then
    select nome into meu_nome from profiles where id = eu;
    insert into connections (nome, tipo, criado_por, linked_user_id)
    values (coalesce(nullif(trim(meu_nome), ''), 'Conexão'), coalesce(tipo_conexao, 'amigos'), r.requester_id, eu);
  end if;

  update link_requests set status = 'aceito', responded_at = now() where id = r.id;
  -- Outros pedidos pendentes pra mesma conexão perdem o sentido.
  update link_requests set status = 'recusado', responded_at = now()
  where connection_id = r.connection_id and status = 'pendente' and id <> r.id;
end $$;

grant execute on function request_link(uuid) to authenticated;
grant execute on function respond_link(uuid, boolean) to authenticated;

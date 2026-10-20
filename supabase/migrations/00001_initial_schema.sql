-- ============================================
-- Little Ember — Schema Inicial MVP
-- ============================================

-- ========================
-- PARTE 1: Enums
-- ========================
create type plan_status as enum ('votando', 'fechado', 'cancelado', 'expirado');
create type member_role as enum ('organizador', 'convidado');
create type vote_disp as enum ('posso', 'talvez', 'nao_posso');
create type place_vote_type as enum ('aprova', 'veta');
create type place_category as enum ('comer', 'beber', 'ar_livre', 'jogos', 'outro');
create type connection_type as enum ('amigos', 'casal', 'familia', 'trabalho', 'outro');

-- ========================
-- PARTE 2: Tabelas (sem policies)
-- ========================

create table profiles (
  id uuid primary key references auth.users on delete cascade,
  nome text not null,
  avatar_url text,
  fuso text not null default 'America/Sao_Paulo',
  fcm_token text,
  created_at timestamptz not null default now()
);

create table places (
  id uuid primary key default gen_random_uuid(),
  nome text not null,
  endereco text not null default '',
  categoria place_category not null default 'outro',
  capacidade int,
  foto_url text,
  criado_por uuid not null references profiles(id) on delete cascade,
  created_at timestamptz not null default now()
);

create table connections (
  id uuid primary key default gen_random_uuid(),
  nome text not null,
  tipo connection_type not null default 'amigos',
  criado_por uuid not null references profiles(id) on delete cascade,
  created_at timestamptz not null default now()
);

create table connection_members (
  id uuid primary key default gen_random_uuid(),
  connection_id uuid not null references connections(id) on delete cascade,
  user_id uuid not null references profiles(id) on delete cascade,
  unique (connection_id, user_id)
);

create table connection_embers (
  id uuid primary key default gen_random_uuid(),
  connection_id uuid not null unique references connections(id) on delete cascade,
  calor float not null default 50.0 check (calor >= 5.0 and calor <= 100.0),
  atualizado_em timestamptz not null default now(),
  cadencia_dias float not null default 21.0,
  ultimo_convite_em timestamptz
);

create table plans (
  id uuid primary key default gen_random_uuid(),
  slug text not null unique,
  criador_id uuid not null references profiles(id) on delete cascade,
  connection_id uuid references connections(id) on delete set null,
  titulo text not null,
  prazo_votacao timestamptz not null,
  status plan_status not null default 'votando',
  horario_final_id uuid,
  lugar_final_id uuid references places(id) on delete set null,
  created_at timestamptz not null default now()
);

create table plan_members (
  id uuid primary key default gen_random_uuid(),
  plan_id uuid not null references plans(id) on delete cascade,
  user_id uuid references profiles(id) on delete set null,
  token text,
  nome_exibicao text not null,
  papel member_role not null default 'convidado',
  created_at timestamptz not null default now()
);

create table time_options (
  id uuid primary key default gen_random_uuid(),
  plan_id uuid not null references plans(id) on delete cascade,
  inicio_utc timestamptz not null,
  fim_utc timestamptz
);

create table time_votes (
  id uuid primary key default gen_random_uuid(),
  time_option_id uuid not null references time_options(id) on delete cascade,
  member_id uuid not null references plan_members(id) on delete cascade,
  disp vote_disp not null,
  unique (time_option_id, member_id)
);

create table place_options (
  id uuid primary key default gen_random_uuid(),
  plan_id uuid not null references plans(id) on delete cascade,
  place_id uuid not null references places(id) on delete cascade,
  unique (plan_id, place_id)
);

create table place_votes (
  id uuid primary key default gen_random_uuid(),
  place_option_id uuid not null references place_options(id) on delete cascade,
  member_id uuid not null references plan_members(id) on delete cascade,
  tipo place_vote_type not null,
  unique (place_option_id, member_id)
);

-- FK pendente (time_options criada depois de plans)
alter table plans
  add constraint fk_horario_final
  foreign key (horario_final_id) references time_options(id) on delete set null;

-- ========================
-- PARTE 3: RLS + Policies
-- ========================

alter table profiles enable row level security;
create policy "Perfil público para leitura" on profiles for select using (true);
create policy "Usuário edita próprio perfil" on profiles for update using (auth.uid() = id);
create policy "Usuário insere próprio perfil" on profiles for insert with check (auth.uid() = id);

alter table places enable row level security;
create policy "Lugares visíveis para logados" on places for select using (auth.uid() is not null);
create policy "Usuário cria lugares" on places for insert with check (auth.uid() = criado_por);
create policy "Criador edita lugar" on places for update using (auth.uid() = criado_por);
create policy "Criador deleta lugar" on places for delete using (auth.uid() = criado_por);

alter table connections enable row level security;
create policy "Membro vê conexão" on connections for select using (
  exists (select 1 from connection_members cm where cm.connection_id = id and cm.user_id = auth.uid())
);
create policy "Usuário cria conexão" on connections for insert with check (auth.uid() = criado_por);
create policy "Criador edita conexão" on connections for update using (auth.uid() = criado_por);
create policy "Criador deleta conexão" on connections for delete using (auth.uid() = criado_por);

alter table connection_members enable row level security;
create policy "Membro vê membros da conexão" on connection_members for select using (
  exists (select 1 from connection_members cm2 where cm2.connection_id = connection_id and cm2.user_id = auth.uid())
);
create policy "Criador da conexão adiciona membro" on connection_members for insert with check (
  exists (select 1 from connections c where c.id = connection_id and c.criado_por = auth.uid())
);
create policy "Criador da conexão remove membro" on connection_members for delete using (
  exists (select 1 from connections c where c.id = connection_id and c.criado_por = auth.uid())
);

alter table connection_embers enable row level security;
create policy "Membro vê brasa da conexão" on connection_embers for select using (
  exists (select 1 from connection_members cm where cm.connection_id = connection_embers.connection_id and cm.user_id = auth.uid())
);
create policy "Membro atualiza brasa" on connection_embers for update using (
  exists (select 1 from connection_members cm where cm.connection_id = connection_embers.connection_id and cm.user_id = auth.uid())
);
create policy "Criador cria brasa" on connection_embers for insert with check (
  exists (select 1 from connections c where c.id = connection_id and c.criado_por = auth.uid())
);

alter table plans enable row level security;
create policy "Plano visível por slug" on plans for select using (true);
create policy "Usuário cria plano" on plans for insert with check (auth.uid() = criador_id);
create policy "Criador edita plano" on plans for update using (auth.uid() = criador_id);

alter table plan_members enable row level security;
create policy "Membros do plano visíveis" on plan_members for select using (true);
create policy "Logado se adiciona ao plano" on plan_members for insert with check (auth.uid() = user_id or user_id is null);

alter table time_options enable row level security;
create policy "Opções de horário visíveis" on time_options for select using (true);
create policy "Criador do plano cria opção de horário" on time_options for insert with check (
  exists (select 1 from plans p where p.id = plan_id and p.criador_id = auth.uid())
);

alter table time_votes enable row level security;
create policy "Votos de horário visíveis" on time_votes for select using (true);
create policy "Membro vota horário" on time_votes for insert with check (
  exists (select 1 from plan_members pm where pm.id = member_id and (pm.user_id = auth.uid() or pm.token is not null))
);
create policy "Membro altera voto" on time_votes for update using (
  exists (select 1 from plan_members pm where pm.id = member_id and (pm.user_id = auth.uid() or pm.token is not null))
);

alter table place_options enable row level security;
create policy "Opções de lugar visíveis" on place_options for select using (true);
create policy "Criador do plano cria opção de lugar" on place_options for insert with check (
  exists (select 1 from plans p where p.id = plan_id and p.criador_id = auth.uid())
);

alter table place_votes enable row level security;
create policy "Votos de lugar visíveis" on place_votes for select using (true);
create policy "Membro vota lugar" on place_votes for insert with check (
  exists (select 1 from plan_members pm where pm.id = member_id and (pm.user_id = auth.uid() or pm.token is not null))
);
create policy "Membro altera voto de lugar" on place_votes for update using (
  exists (select 1 from plan_members pm where pm.id = member_id and (pm.user_id = auth.uid() or pm.token is not null))
);

-- ========================
-- PARTE 4: Trigger, Realtime, Índices
-- ========================

create or replace function handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, nome, avatar_url)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'full_name', new.raw_user_meta_data->>'name', 'Usuário'),
    new.raw_user_meta_data->>'avatar_url'
  );
  return new;
end;
$$ language plpgsql security definer;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function handle_new_user();

alter publication supabase_realtime add table time_votes;
alter publication supabase_realtime add table place_votes;
alter publication supabase_realtime add table plan_members;

create index idx_plans_slug on plans(slug);
create index idx_plans_criador on plans(criador_id);
create index idx_plan_members_plan on plan_members(plan_id);
create index idx_plan_members_user on plan_members(user_id);
create index idx_time_options_plan on time_options(plan_id);
create index idx_time_votes_option on time_votes(time_option_id);
create index idx_place_options_plan on place_options(plan_id);
create index idx_place_votes_option on place_votes(place_option_id);
create index idx_connection_members_conn on connection_members(connection_id);
create index idx_connection_members_user on connection_members(user_id);

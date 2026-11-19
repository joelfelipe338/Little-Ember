-- =====================================================================
-- CHAMMA · 00006 · Grupos de conexões + brasa (último rolê juntos)
-- =====================================================================

-- ------------------------------------------------------------- grupos
create table if not exists contact_groups (
  id uuid primary key default gen_random_uuid(),
  nome text not null check (char_length(trim(nome)) between 1 and 40),
  cor text not null default 'lavanda'
    check (cor in ('lavanda', 'brasa', 'menta', 'sol', 'neblina')),
  criado_por uuid not null references profiles(id) on delete cascade,
  created_at timestamptz not null default now()
);

create table if not exists contact_group_members (
  group_id uuid not null references contact_groups(id) on delete cascade,
  connection_id uuid not null references connections(id) on delete cascade,
  primary key (group_id, connection_id)
);

create index if not exists idx_contact_groups_owner on contact_groups(criado_por);
create index if not exists idx_contact_group_members_conn on contact_group_members(connection_id);

alter table contact_groups enable row level security;

drop policy if exists "Dono vê grupos" on contact_groups;
drop policy if exists "Dono cria grupos" on contact_groups;
drop policy if exists "Dono edita grupos" on contact_groups;
drop policy if exists "Dono apaga grupos" on contact_groups;
create policy "Dono vê grupos" on contact_groups for select using (auth.uid() = criado_por);
create policy "Dono cria grupos" on contact_groups for insert with check (auth.uid() = criado_por);
create policy "Dono edita grupos" on contact_groups for update
  using (auth.uid() = criado_por) with check (auth.uid() = criado_por);
create policy "Dono apaga grupos" on contact_groups for delete using (auth.uid() = criado_por);

alter table contact_group_members enable row level security;

drop policy if exists "Dono vê membros do grupo" on contact_group_members;
drop policy if exists "Dono adiciona ao grupo" on contact_group_members;
drop policy if exists "Dono remove do grupo" on contact_group_members;
create policy "Dono vê membros do grupo" on contact_group_members for select using (
  exists (select 1 from contact_groups g where g.id = group_id and g.criado_por = auth.uid())
);
-- Só põe no grupo conexões que também são suas.
create policy "Dono adiciona ao grupo" on contact_group_members for insert with check (
  exists (select 1 from contact_groups g where g.id = group_id and g.criado_por = auth.uid())
  and exists (select 1 from connections c where c.id = connection_id and c.criado_por = auth.uid())
);
create policy "Dono remove do grupo" on contact_group_members for delete using (
  exists (select 1 from contact_groups g where g.id = group_id and g.criado_por = auth.uid())
);

-- ------------------------------------------------------------- brasa
-- Liga o convidado do rolê à conexão de quem organizou. Com isso o app
-- sabe qual foi o último rolê com cada pessoa (brasa quente / esfriando).
alter table plan_members
  add column if not exists connection_id uuid references connections(id) on delete set null;

create index if not exists idx_plan_members_connection on plan_members(connection_id);

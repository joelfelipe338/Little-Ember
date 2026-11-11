-- =====================================================================
-- CHAMMA · 00002 · Página do convidado (link web)
--
-- O convidado entra pelo link sem criar conta: o app abre uma sessão
-- anônima do Supabase (Auth → Providers → "Allow anonymous sign-ins").
-- Assim todo membro tem user_id = auth.uid() e o RLS fica simples e seguro.
-- =====================================================================

-- Uma pessoa entra no mesmo rolê uma vez só.
create unique index if not exists plan_members_plan_user_uniq
  on plan_members (plan_id, user_id)
  where user_id is not null;

-- ------------------------------------------------------------- plan_members
drop policy if exists "Logado se adiciona ao plano" on plan_members;

-- Só se adiciona a si mesmo, como convidado, enquanto a votação está aberta.
-- (O organizador é inserido pelo próprio criador do rolê.)
create policy "Entra no rolê pelo link" on plan_members for insert with check (
  auth.uid() = user_id
  and (
    (papel = 'convidado' and exists (
      select 1 from plans p
      where p.id = plan_id and p.status = 'votando' and p.prazo_votacao > now()
    ))
    or
    (papel = 'organizador' and exists (
      select 1 from plans p where p.id = plan_id and p.criador_id = auth.uid()
    ))
  )
);

-- Cada um pode trocar o próprio nome de exibição.
drop policy if exists "Membro edita o próprio nome" on plan_members;
create policy "Membro edita o próprio nome" on plan_members for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- ------------------------------------------------------------- time_votes
drop policy if exists "Membro vota horário" on time_votes;
drop policy if exists "Membro altera voto" on time_votes;

-- Vota só por si mesmo, só em opções do próprio rolê e só com a votação aberta.
create policy "Membro vota horário" on time_votes for insert with check (
  exists (
    select 1
    from plan_members pm
    join time_options o on o.id = time_option_id and o.plan_id = pm.plan_id
    join plans p on p.id = pm.plan_id
    where pm.id = member_id
      and pm.user_id = auth.uid()
      and p.status = 'votando'
      and p.prazo_votacao > now()
  )
);

create policy "Membro altera voto" on time_votes for update
  using (
    exists (select 1 from plan_members pm where pm.id = member_id and pm.user_id = auth.uid())
  )
  with check (
    exists (
      select 1
      from plan_members pm
      join time_options o on o.id = time_option_id and o.plan_id = pm.plan_id
      join plans p on p.id = pm.plan_id
      where pm.id = member_id
        and pm.user_id = auth.uid()
        and p.status = 'votando'
        and p.prazo_votacao > now()
    )
  );

-- ------------------------------------------------------------- place_votes
drop policy if exists "Membro vota lugar" on place_votes;
drop policy if exists "Membro altera voto de lugar" on place_votes;

create policy "Membro vota lugar" on place_votes for insert with check (
  exists (select 1 from plan_members pm where pm.id = member_id and pm.user_id = auth.uid())
);
create policy "Membro altera voto de lugar" on place_votes for update
  using (exists (select 1 from plan_members pm where pm.id = member_id and pm.user_id = auth.uid()))
  with check (exists (select 1 from plan_members pm where pm.id = member_id and pm.user_id = auth.uid()));

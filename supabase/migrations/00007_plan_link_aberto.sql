-- =====================================================================
-- CHAMMA · 00007 · Novo rolê: link aberto ou só para convidados
--
-- link_aberto = true  -> qualquer um com o link entra (padrão).
-- link_aberto = false -> só quem o organizador adicionou pode entrar
--                        (o convidado escolhe o próprio nome na lista).
-- =====================================================================

alter table plans add column if not exists link_aberto boolean not null default true;

-- Recria a entrada pelo link exigindo link aberto para quem não estava na lista.
drop policy if exists "Entra no rolê pelo link" on plan_members;
create policy "Entra no rolê pelo link" on plan_members for insert with check (
  auth.uid() = user_id
  and (
    (papel = 'convidado' and exists (
      select 1 from plans p
      where p.id = plan_id
        and p.status = 'votando'
        and p.prazo_votacao > now()
        and p.link_aberto
    ))
    or
    (papel = 'organizador' and exists (
      select 1 from plans p where p.id = plan_id and p.criador_id = auth.uid()
    ))
  )
);

-- (Futuro) O local do rolê será escolhido num mapa e gravado em
-- plans.lugar_final_id -> places (já existe no schema inicial).

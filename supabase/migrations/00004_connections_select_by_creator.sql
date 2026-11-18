-- A policy original ("Membro vê conexão") faz SELECT em connection_members,
-- cuja própria policy SELECT se auto-referencia, causando recursão infinita.
-- Como usamos connections como contatos simples (sem connection_members),
-- dropamos a policy problemática e usamos apenas criado_por.

DROP POLICY IF EXISTS "Membro vê conexão" ON connections;

CREATE POLICY "Criador vê própria conexão"
  ON connections FOR SELECT
  USING (auth.uid() = criado_por);

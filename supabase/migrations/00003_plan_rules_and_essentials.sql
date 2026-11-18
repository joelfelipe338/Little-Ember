-- Regras do rolê e pessoas essenciais

ALTER TABLE plans ADD COLUMN votos_visiveis boolean NOT NULL DEFAULT true;
ALTER TABLE plans ADD COLUMN quorum_minimo int NOT NULL DEFAULT 0;
ALTER TABLE plans ADD COLUMN sem_resposta_conta_como text NOT NULL DEFAULT 'nada';
ALTER TABLE plans ADD COLUMN essencial_visivel boolean NOT NULL DEFAULT false;

ALTER TABLE plans ADD CONSTRAINT chk_sem_resposta
  CHECK (sem_resposta_conta_como IN ('nada', 'nao_posso'));

ALTER TABLE plan_members ADD COLUMN essencial boolean NOT NULL DEFAULT false;

-- Organizador pode pré-adicionar convidados (user_id NULL)
CREATE POLICY "Organizador adiciona convidados ao plano"
  ON plan_members FOR INSERT WITH CHECK (
    user_id IS NULL
    AND papel = 'convidado'
    AND EXISTS (
      SELECT 1 FROM plans p WHERE p.id = plan_id AND p.criador_id = auth.uid()
    )
  );

-- Convidado reivindica vaga pré-adicionada
CREATE POLICY "Convidado reivindica vaga"
  ON plan_members FOR UPDATE
  USING (
    user_id IS NULL
    AND EXISTS (
      SELECT 1 FROM plans p
      WHERE p.id = plan_id
        AND p.status = 'votando'
        AND p.prazo_votacao > now()
    )
  )
  WITH CHECK (auth.uid() = user_id);

-- Novas configurações de rolê

ALTER TABLE plans ADD COLUMN auto_fechar boolean NOT NULL DEFAULT false;
ALTER TABLE plans ADD COLUMN permitir_sugestoes boolean NOT NULL DEFAULT false;
ALTER TABLE plans ADD COLUMN voto_anonimo boolean NOT NULL DEFAULT false;
ALTER TABLE plans ADD COLUMN limite_posso int NOT NULL DEFAULT 0;
ALTER TABLE plans ADD COLUMN lembrete_horas int NOT NULL DEFAULT 0;

-- Membro pode sugerir horário quando o plano permite
CREATE POLICY "Membro sugere horário"
  ON time_options FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM plans p
      JOIN plan_members pm ON pm.plan_id = p.id
      WHERE p.id = plan_id
        AND pm.user_id = auth.uid()
        AND p.permitir_sugestoes = true
        AND p.status = 'votando'
        AND p.prazo_votacao > now()
    )
  );

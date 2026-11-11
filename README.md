# CHAMMA

A chama que mantém a amizade acesa. App Flutter para marcar rolês em grupo: quem cria manda um link, a galera vota (sem instalar nada) e o app decide.

## Stack

- Flutter + Riverpod + go_router
- Supabase (Postgres, Auth, RLS) — migrações em `supabase/migrations/`
- Web publicada no GitHub Pages (`.github/workflows/deploy-web.yml`)

## Rodando

```bash
flutter pub get
flutter run
```

Design: `docs/design/ember_retro_design.md` (estilo "Retrô sem pixel", tema claro e escuro).

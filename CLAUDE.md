# Little Ember

App Flutter (Riverpod + go_router + Supabase) para marcar rolês em grupo.

## Design
@docs/design/ember_retro_design.md

- O estilo oficial do app é o "Retrô sem pixel", descrito no guia acima.
- Toda tela nova ou refeita usa os tokens e widgets de `lib/theme/ember_retro_theme.dart` (`EmberColors`, `EmberText`, `RetroScaffold`, `RetroButton`, `RetroCard` etc.).
- Os arquivos em `lib/core/theme/` e os widgets em `lib/shared/widgets/` são do estilo antigo (neubrutalism). Não use em telas novas: migre para o tema retrô ao mexer numa tela.
- Referências visuais das telas ficam em `docs/design/screens/`.
- Tema claro e escuro disponíveis. Toggle no perfil via `themeModeProvider`.

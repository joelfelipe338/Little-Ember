# CHAMMA

> Nome do app: **CHAMMA** (antes "Little Ember"). Classes e arquivos com "Ember" no nome (EmberColors, EmberLogo, ember_retro_theme...) seguem o conceito de brasa e continuam com esse nome.

App Flutter (Riverpod + go_router + Supabase) para marcar rolês em grupo.

## Design
@docs/design/ember_retro_design.md

- O estilo oficial do app é o "Retrô sem pixel", descrito no guia acima.
- Toda tela nova ou refeita usa os tokens e widgets de `lib/theme/ember_retro_theme.dart` (`EmberColors`, `EmberText`, `RetroScaffold`, `RetroButton`, `RetroCard` etc.).
- Os arquivos em `lib/core/theme/` e os widgets em `lib/shared/widgets/` são do estilo antigo (neubrutalism). Não use em telas novas: migre para o tema retrô ao mexer numa tela.
- Referências visuais das telas ficam em `docs/design/screens/`.
- O app tem tema claro e escuro (`EmberRetroTheme.light()` / `.dark()`), alternados pelo `themeModeProvider` (toggle no Perfil). Nas telas, cores de fundo, texto e contorno vêm de `RetroPalette.of(context)`, nunca de `EmberColors.creme/branco/tinta`. `EmberColors.tinta` só para texto sobre cores de marca (sol, menta, lavanda, coral). No escuro, a moldura é índigo (#2A2558), não vermelha.

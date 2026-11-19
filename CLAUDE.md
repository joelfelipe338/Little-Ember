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

## Próximos passos (lembrar)
- **Vínculo de conexões** (feito: tabela `link_requests`, funções `request_link`/`respond_link`, migração 00008). Falta:
  - Links https abrindo no app: configurado para `chamma.site` (Android `autoVerify` no AndroidManifest, iOS `Runner.entitlements`, arquivos em `web/.well-known/`). **Falta preencher** o SHA-256 da chave Android em `web/.well-known/assetlinks.json` e o Team ID da Apple em `web/.well-known/apple-app-site-association`.
  - Notificação push para o dono quando chega um pedido de vínculo (hoje aparece no topo das Conexões).
- **Código de convite** (`profiles.codigo_convite`): por enquanto só aparece no Perfil. Falta: adicionar amigo pelo código (vira conexão vinculada direto).
- **Cutucar / avisos**: hoje "Cutucar" compartilha uma mensagem de cobrança. Com push, mandar aviso direto pra quem tem o app.
- **Foto de perfil**: o campo `avatar_url` existe; falta upload (Supabase Storage) na tela Editar perfil.
- **Avisos**: o interruptor do Perfil só guarda a preferência (`notificationsEnabledProvider`). Quando houver push, respeitar essa escolha.

## Site
- Domínio: **https://chamma.site** (GitHub Pages, arquivo `web/CNAME`). Link do convidado: `https://chamma.site/#/r/<slug>` (`AppConstants.guestLink`).
- Deploy: `.github/workflows/deploy-web.yml` (base-href `/`, copia CNAME, `.nojekyll` e `.well-known`).

## Local no mapa
- Escolha em `lib/features/places/presentation/map_picker_screen.dart` (rota `/map-picker`, devolve `PlaceDraft`). Mapa: `flutter_map` + tiles do OpenStreetMap; busca de endereço: Nominatim (`GeocodingService`, máx. 1 busca/s).
- O local fica em `places` (com `latitude`/`longitude`) e o rolê aponta em `plans.lugar_final_id`. `PlaceCard` mostra o mapinha e abre o app de mapas.
- Antes de publicar nas lojas: trocar os tiles do OpenStreetMap por um provedor com chave (MapTiler, Stadia, Mapbox). A política do OSM não permite uso pesado em app.

## Assinatura (CHAMMA+)
- Planos: `profiles.plano` ('gratis' | 'plus') + `plano_expira_em`. Limites na tabela `plan_limits` (dá pra editar os números no painel do Supabase).
- Grátis: 3 rolês em votação, 5 horários e 15 pessoas por rolê, 3 grupos, só modo Normal. Plus: sem esses limites + modos Rápido e Secreto.
- O banco barra tudo (triggers da migração 00009) e o usuário não consegue mudar o próprio plano. **Para testar**: no Table Editor, mude `profiles.plano` do seu usuário para `plus`.
- App: `subscriptionProvider` (limites valendo agora), `showPlusSheet` (aviso de recurso Plus), tela `/assinatura`. Falta: pagamento (RevenueCat / Google Play Billing / App Store).

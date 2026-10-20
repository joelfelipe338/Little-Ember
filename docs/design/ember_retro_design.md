# Design system — Little Ember · "Retrô sem pixel"

> Guia para quem for implementar telas neste app (humano ou Claude Code).
> Código base: `lib/theme/ember_retro_theme.dart`. Referências visuais: `docs/design/screens/*.png`.
> **Sempre use os tokens e widgets do tema. Nunca escreva cores, raios ou sombras soltos nas telas.**
> As telas de exemplo do canvas mostram o **estilo**. Não copie o conteúdo delas ao pé da letra: o conteúdo de cada tela vem das funcionalidades reais do app.

## Conceito

Um painel de "rastreador" de rolês: uma **moldura coral** envolve uma **tela creme** com grade fina e régua no topo. Tudo tem **contorno escuro grosso**, **cantos arredondados** e **sombra sólida sem blur**. Os botões têm volume e **afundam ao toque**. Visual de console retrô, mas **sem pixel art**: formas vetoriais lisas, fontes normais, ícones de traço.

## Tokens (`EmberColors`, `EmberRetro`, `EmberText`)

| Uso | Token | Valor |
|---|---|---|
| Moldura (fundo do Scaffold), status "votando" | `EmberColors.brasa` | #FF5A4E |
| CTA principal, item ativo da navegação | `EmberColors.sol` | #FFC43D |
| "Decidido" / "posso" | `EmberColors.menta` | #12B886 |
| "Talvez", foco de input, detalhe da placa | `EmberColors.lavanda` | #8B7BFF |
| "Encerrado" / "não posso" | `EmberColors.neblina` | #B9B6C4 |
| Fundo da tela interna | `EmberColors.creme` | #FFF8F1 |
| Cards e inputs | `EmberColors.branco` | #FFFFFF |
| Contornos, sombras e texto principal | `EmberColors.tinta` | #1B1A2E |
| Texto secundário | `EmberColors.textoSecundario` | #5E5B6E |
| Texto vermelho sobre branco (ex.: "Sair da conta") | `EmberColors.brasaTexto` | #B02A22 |

- **Contorno**: 3px tinta em tudo (`EmberRetro.contorno`). Tags e avatares pequenos usam 2px.
- **Raios**: tela 20 · card 18 · botão e input 14 · tags e chips em pílula (999).
- **Sombras**: botão = `BoxShadow(tinta, Offset(0, 5))`, que vai para `Offset(0, 2)` quando pressionado e desce o botão 3px. Card = `EmberRetro.sombraCard` (tinta 16%, `Offset(0, 6)`). **Nunca use blur.**
- **Tipografia**:
  - `EmberText.display` (Bricolage Grotesque 800) → títulos, nomes, números.
  - `EmberText.mono` (Space Mono 700, CAIXA ALTA) → rótulos de campo, tags, letreiro, contadores ("FECHA EM 1D 4H").
  - `EmberText.body` (Inter) → texto corrido e botões.
- **Espaçamento**: moldura com margem lateral de 12. Blocos da moldura separados por 14. Tela interna com padding de 14 a 22. Gap entre cards de 16.
- **Toque**: alvos de no mínimo 44px.

## Estrutura de toda tela (`RetroScaffold`)

```
Scaffold (fundo brasa)
 └ topo, 54px: [RetroButton.icon] — RetroPlaque — [RetroButton.icon]
 └ RetroPanel (tela creme + grade + régua, ocupa o resto)
 └ RetroTicker (letreiro com novidades dos rolês)
 └ RetroNavBar (Mapa · Rolês · Perfil)
```

O login não tem navegação inferior nem botões nos cantos, só a placa "LITTLE (chama) EMBER".

## Componentes

- **RetroButton**: primário em `sol`. Secundário em `creme`/`branco`. Escuro em `tinta` com texto creme (ex.: Apple). Use `shape: pill` para FAB e "Sair", e `RetroButton.icon` para os cantos do topo e os controles do mapa.
- **RetroCard**: itens de lista, card de perfil, card de pré-visualização no mapa.
- **RetroTag**: status do rolê; a cor vem de `RoleStatus.color`.
- **RetroPlaque**: placa preta em pílula com borda interna lavanda, texto amarelo e um emblema circular creme no meio (chama ou mascote).
- **RetroTicker**: frases curtas em CAIXA ALTA separadas por " • ". Para quando o sistema pede menos animação.
- **Inputs**: rótulo em `EmberText.mono(12)` **acima** do campo (não use `labelText` flutuante). O campo já vem estilizado pelo `inputDecorationTheme`.
- **Abas laterais do mapa**: botões presos à borda esquerda, com raio só à direita (`BorderRadius.horizontal(right: Radius.circular(20))`).
- **Pinos no mapa**: círculos de 38px na cor do status, com contorno e sombra, e a chama creme dentro.
- **Radar**: círculos concêntricos lavanda, varredura coral girando (4s por volta), pontos com a cor do status.
- **Mascote "Brasinha"**: chama coral vetorial com olhos brancos, bochechas e sorriso. Aparece no login (balão de fala) e em estados vazios.

### Widgets prontos do app (`lib/shared/widgets/`)

- `RetroTopBar(left:, right:, emblem:, leading:, trailing:)`: o topo padrão. A placa fica centralizada e as ações vão nos cantos.
- `EmberFlame(size:)`: o logo da chama, no lugar do emoji 🔥. `Brasinha(size:)` é o mascote, que flutua de leve.
- `RetroFieldLabel('Email')`: o rótulo mono que vai acima de cada input.
- `RetroErrorBox(msg)`: o erro de formulário. `RetroButtonSpinner()`: o loading dentro de botões.
- `RetroEmptyState(illustration:, title:, message:, action:)`: o estado vazio padrão.
- `EmberButton`, `EmberCard` e `VoteChip` já seguem o estilo retrô e podem continuar sendo usados.
- As telas das abas ficam dentro do `AppShell`, que tem a navegação retrô. Cada tela usa `RetroScaffold` **sem** `bottomNav`.

## Padrões de tela

- **Login**: placa → tela com o mascote e um balão de fala → título "Entrar no jogo" → email/senha → ENTRAR (sol, com ▶) → "ou" → Google | Apple → "Novo por aqui? Criar conta".
- **Mapa**: mapa claro (terra `mapaTerra`, água `mapaAgua`, parques `mapaParque`, avenidas brancas com borda bege). Tocar num pino abre o card com foto, tag, título, data e "VER ROLÊ →". Radar no canto inferior direito, zoom à direita.
- **Rolês (lista)**: título "Seus rolês" + contador mono → filtros em pílula (o ativo fica com fundo tinta e texto sol) → cards (tag + prazo, título, data, avatares, barra de votos menta) → FAB "Novo rolê".
- **Perfil**: card do jogador (avatar redondo sol com inicial + tag "P1", nome, "ANFITRIÃO DE ROLÊS") → 2 blocos de números → card de campos (Nome, Email, Fuso) que vira inputs no modo edição (lápis/check no canto) → Aparência (segmentado em pílula) → "Sair da conta".

## Não faça

- Pixel art, fontes pixeladas ou ícones em grade.
- Sombras com blur, gradientes de fundo ou bordas finas de 1px em elementos de UI.
- Texto branco sobre coral, menta, lavanda ou amarelo (contraste ruim). Use tinta.
- Emojis como ícone.
- Cores hardcoded nas telas. Se faltar um token, adicione em `EmberColors`.

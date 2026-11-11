// CHAMMA — estilo "Retrô sem pixel"
// Tokens + ThemeData (claro e escuro) + widgets base. Depende de: google_fonts
//
// Uso:
//   MaterialApp(theme: EmberRetroTheme.light(), darkTheme: EmberRetroTheme.dark(), themeMode: ...)
//
// Cores que mudam entre claro/escuro (fundo, texto, contorno...) vêm de
// RetroPalette.of(context). Cores de marca/status (sol, menta, lavanda, brasa...)
// são fixas em EmberColors e sempre levam texto em EmberColors.tinta por cima.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ---------------------------------------------------------------------------
// TOKENS FIXOS (iguais nos dois temas)
// ---------------------------------------------------------------------------

abstract final class EmberColors {
  // Marca e status
  static const brasa = Color(0xFFFF5A4E); // moldura no claro / "votando"
  static const brasaForte = Color(0xFFD9382E);
  static const sol = Color(0xFFFFC43D); // CTA principal / item ativo
  static const menta = Color(0xFF12B886); // "decidido" / "posso"
  static const lavanda = Color(0xFF8B7BFF); // "talvez" / foco / detalhes da placa
  static const neblina = Color(0xFFB9B6C4); // "encerrado" / "não posso"
  static const indigoNoite = Color(0xFF2A2558); // moldura no escuro

  // Base clara (use RetroPalette.of(context) nas telas)
  static const creme = Color(0xFFFFF8F1);
  static const branco = Color(0xFFFFFFFF);
  static const tinta = Color(0xFF1B1A2E); // texto sobre cores de marca/status, em qualquer tema
  static const textoSecundario = Color(0xFF5E5B6E);
  static const linhaSuave = Color(0xFFEFE6DA);
  static const brasaTexto = Color(0xFFB02A22);
  static const erroFundo = Color(0xFFFFE9E6);

  // Mapa (claro)
  static const mapaTerra = Color(0xFFFBEBD6);
  static const mapaAgua = Color(0xFFBDE8DA);
  static const mapaParque = Color(0xFFCDEDD8);

  // Legado (tema neubrutalism em lib/core/theme). Não use em telas novas.
  static const noite = tinta;
  static const noiteSurface = Color(0xFF252438);
  static const noiteCard = Color(0xFF2F2E42);
}

abstract final class EmberRetro {
  static const borda = 3.0; // contorno padrão de tudo
  static const raioTela = 20.0; // painel interno (a "tela")
  static const raioCard = 18.0;
  static const raioBotao = 14.0;
  static const raioInput = 14.0;
  static const profundidadeBotao = 5.0; // sombra sólida sob o botão
  static const profundidadePressionado = 2.0;
  static const espacoGrade = 22.0; // grade de fundo da tela
  static const margemMoldura = 12.0;
}

// ---------------------------------------------------------------------------
// PALETA POR TEMA
// ---------------------------------------------------------------------------

@immutable
class RetroPalette extends ThemeExtension<RetroPalette> {
  const RetroPalette({
    required this.moldura,
    required this.tela,
    required this.superficie,
    required this.botaoSecundario,
    required this.texto,
    required this.textoSecundario,
    required this.contorno,
    required this.linhaSuave,
    required this.grade,
    required this.regua,
    required this.sombraCard,
    required this.erroFundo,
    required this.erroTexto,
    required this.invertido,
    required this.noInvertido,
  });

  /// Fundo da moldura (fora da tela interna).
  final Color moldura;

  /// Fundo da tela interna (RetroPanel).
  final Color tela;

  /// Cards, inputs, botões brancos.
  final Color superficie;

  /// Botões secundários na moldura (cantos do topo, abas inativas).
  final Color botaoSecundario;
  final Color texto;
  final Color textoSecundario;

  /// Contornos e sombras sólidas.
  final Color contorno;
  final Color linhaSuave;
  final Color grade;
  final Color regua;
  final Color sombraCard;
  final Color erroFundo;
  final Color erroTexto;

  /// Fundo "invertido" (ex.: botão Apple, snackbar) e o texto sobre ele.
  final Color invertido;
  final Color noInvertido;

  static const light = RetroPalette(
    moldura: EmberColors.brasa,
    tela: EmberColors.creme,
    superficie: EmberColors.branco,
    botaoSecundario: EmberColors.creme,
    texto: EmberColors.tinta,
    textoSecundario: EmberColors.textoSecundario,
    contorno: EmberColors.tinta,
    linhaSuave: EmberColors.linhaSuave,
    grade: Color(0x0D1B1A2E),
    regua: Color(0xFF1B1A2E),
    sombraCard: Color(0x291B1A2E),
    erroFundo: EmberColors.erroFundo,
    erroTexto: EmberColors.brasaTexto,
    invertido: EmberColors.tinta,
    noInvertido: EmberColors.creme,
  );

  static const dark = RetroPalette(
    moldura: EmberColors.indigoNoite,
    tela: Color(0xFF1B1A2E),
    superficie: Color(0xFF2F2E42),
    botaoSecundario: Color(0xFF2F2E42),
    texto: EmberColors.creme,
    textoSecundario: EmberColors.neblina,
    contorno: Color(0xFF0B0A14),
    linhaSuave: Color(0xFF3A3950),
    grade: Color(0x0DFFFFFF),
    regua: Color(0xFFFFFFFF),
    sombraCard: Color(0x73000000),
    erroFundo: Color(0xFF3A1F27),
    erroTexto: Color(0xFFFF8A7E),
    invertido: EmberColors.creme,
    noInvertido: EmberColors.tinta,
  );

  static RetroPalette of(BuildContext context) =>
      Theme.of(context).extension<RetroPalette>() ?? light;

  Border get contornoBorda => Border.all(color: contorno, width: EmberRetro.borda);

  BoxShadow get sombraDeCard => BoxShadow(color: sombraCard, offset: const Offset(0, 6));

  @override
  RetroPalette copyWith({
    Color? moldura,
    Color? tela,
    Color? superficie,
    Color? botaoSecundario,
    Color? texto,
    Color? textoSecundario,
    Color? contorno,
    Color? linhaSuave,
    Color? grade,
    Color? regua,
    Color? sombraCard,
    Color? erroFundo,
    Color? erroTexto,
    Color? invertido,
    Color? noInvertido,
  }) =>
      RetroPalette(
        moldura: moldura ?? this.moldura,
        tela: tela ?? this.tela,
        superficie: superficie ?? this.superficie,
        botaoSecundario: botaoSecundario ?? this.botaoSecundario,
        texto: texto ?? this.texto,
        textoSecundario: textoSecundario ?? this.textoSecundario,
        contorno: contorno ?? this.contorno,
        linhaSuave: linhaSuave ?? this.linhaSuave,
        grade: grade ?? this.grade,
        regua: regua ?? this.regua,
        sombraCard: sombraCard ?? this.sombraCard,
        erroFundo: erroFundo ?? this.erroFundo,
        erroTexto: erroTexto ?? this.erroTexto,
        invertido: invertido ?? this.invertido,
        noInvertido: noInvertido ?? this.noInvertido,
      );

  @override
  RetroPalette lerp(RetroPalette? other, double t) {
    if (other == null) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return RetroPalette(
      moldura: l(moldura, other.moldura),
      tela: l(tela, other.tela),
      superficie: l(superficie, other.superficie),
      botaoSecundario: l(botaoSecundario, other.botaoSecundario),
      texto: l(texto, other.texto),
      textoSecundario: l(textoSecundario, other.textoSecundario),
      contorno: l(contorno, other.contorno),
      linhaSuave: l(linhaSuave, other.linhaSuave),
      grade: l(grade, other.grade),
      regua: l(regua, other.regua),
      sombraCard: l(sombraCard, other.sombraCard),
      erroFundo: l(erroFundo, other.erroFundo),
      erroTexto: l(erroTexto, other.erroTexto),
      invertido: l(invertido, other.invertido),
      noInvertido: l(noInvertido, other.noInvertido),
    );
  }
}

/// Compatibilidade com telas que usam os nomes antigos (ex.: create_plan_screen).
/// Lê tudo da RetroPalette. Em código novo, use RetroPalette.of(context).
class RetroTokens {
  const RetroTokens._(this._p);

  final RetroPalette _p;

  static RetroTokens of(BuildContext context) => RetroTokens._(RetroPalette.of(context));

  Color get panelBg => _p.tela;
  Color get cardBg => _p.superficie;
  Color get inputBg => _p.superficie;
  Color get textPrimary => _p.texto;
  Color get textSecondary => _p.textoSecundario;
  Color get border => _p.contorno;
  Color get shadow => _p.sombraCard;
  Color get gridLine => _p.grade;
  Color get divider => _p.linhaSuave;
  Color get errorBg => _p.erroFundo;
  Color get scaffoldBg => _p.moldura;
}

// ---------------------------------------------------------------------------
// TIPOGRAFIA
// ---------------------------------------------------------------------------

/// Sem `color`, o texto herda a cor do tema (claro ou escuro).
abstract final class EmberText {
  /// Títulos e números de destaque.
  static TextStyle display(double size, {Color? color}) => GoogleFonts.bricolageGrotesque(
        fontSize: size,
        fontWeight: FontWeight.w800,
        height: 1.05,
        letterSpacing: -0.03 * size,
        color: color,
      );

  /// Rótulos em caixa alta, tags, letreiro (o ar de "painel de rastreador").
  static TextStyle mono(double size, {Color? color}) => GoogleFonts.spaceMono(
        fontSize: size,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.06 * size,
        color: color,
      );

  /// Corpo de texto.
  static TextStyle body(double size, {Color? color, FontWeight weight = FontWeight.w500}) =>
      GoogleFonts.inter(fontSize: size, fontWeight: weight, color: color);
}

// ---------------------------------------------------------------------------
// THEME
// ---------------------------------------------------------------------------

abstract final class EmberRetroTheme {
  static ThemeData light() => _build(RetroPalette.light, Brightness.light);
  static ThemeData dark() => _build(RetroPalette.dark, Brightness.dark);

  static ThemeData _build(RetroPalette p, Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: EmberColors.brasa,
      brightness: brightness,
    ).copyWith(
      primary: EmberColors.sol,
      onPrimary: EmberColors.tinta,
      secondary: EmberColors.brasa,
      onSecondary: EmberColors.tinta,
      tertiary: EmberColors.lavanda,
      surface: p.tela,
      onSurface: p.texto,
      onSurfaceVariant: p.textoSecundario,
      outline: p.contorno,
      error: p.erroTexto,
    );

    final base = ThemeData(useMaterial3: true, brightness: brightness, colorScheme: scheme);
    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(EmberRetro.raioInput),
      borderSide: BorderSide(color: p.contorno, width: EmberRetro.borda),
    );

    return base.copyWith(
      scaffoldBackgroundColor: p.moldura,
      extensions: [p],
      textTheme: GoogleFonts.interTextTheme(base.textTheme)
          .apply(bodyColor: p.texto, displayColor: p.texto)
          .copyWith(
            headlineLarge: EmberText.display(34, color: p.texto),
            headlineMedium: EmberText.display(30, color: p.texto),
            titleLarge: EmberText.display(21, color: p.texto),
            titleMedium: EmberText.display(17, color: p.texto),
            bodyLarge: EmberText.body(16, color: p.texto),
            bodyMedium: EmberText.body(14, color: p.texto),
            labelLarge: EmberText.body(15, color: p.texto, weight: FontWeight.w800),
            labelSmall: EmberText.mono(10, color: p.texto),
          ),
      iconTheme: IconThemeData(color: p.texto),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.superficie,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        hintStyle: EmberText.body(16, color: p.textoSecundario),
        helperStyle: EmberText.body(12, color: p.textoSecundario),
        errorStyle: EmberText.body(12, color: p.erroTexto, weight: FontWeight.w600),
        suffixIconColor: p.textoSecundario,
        border: inputBorder,
        enabledBorder: inputBorder,
        focusedBorder: inputBorder.copyWith(
          borderSide: const BorderSide(color: EmberColors.lavanda, width: EmberRetro.borda),
        ),
        errorBorder: inputBorder.copyWith(
          borderSide: const BorderSide(color: EmberColors.brasaForte, width: EmberRetro.borda),
        ),
        focusedErrorBorder: inputBorder.copyWith(
          borderSide: const BorderSide(color: EmberColors.brasaForte, width: EmberRetro.borda),
        ),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: p.texto,
        selectionColor: EmberColors.lavanda.withAlpha(90),
        selectionHandleColor: EmberColors.lavanda,
      ),
      dividerTheme: DividerThemeData(color: p.linhaSuave, thickness: 2),
      splashFactory: NoSplash.splashFactory, // o "afundar" do botão substitui o ripple
      dialogTheme: DialogThemeData(
        backgroundColor: p.tela,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(EmberRetro.raioCard),
          side: BorderSide(color: p.contorno, width: EmberRetro.borda),
        ),
        titleTextStyle: EmberText.display(22, color: p.texto),
        contentTextStyle: EmberText.body(15, color: p.texto),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: p.texto,
          textStyle: EmberText.body(15, weight: FontWeight.w800),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: p.invertido,
        contentTextStyle: EmberText.body(14, color: p.noInvertido, weight: FontWeight.w600),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(EmberRetro.raioBotao)),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: p.texto),
    );
  }
}

// ---------------------------------------------------------------------------
// WIDGETS BASE
// ---------------------------------------------------------------------------

/// Estrutura de toda tela: moldura > topo > tela interna > letreiro > navegação.
class RetroScaffold extends StatelessWidget {
  const RetroScaffold({
    super.key,
    required this.top,
    required this.body,
    this.ticker,
    this.bottomNav,
    this.panelPadding = const EdgeInsets.fromLTRB(14, 26, 14, 18),
  });

  final Widget top;
  final Widget body;
  final String? ticker;
  final Widget? bottomNav;
  final EdgeInsets panelPadding;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RetroPalette.of(context).moldura,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            EmberRetro.margemMoldura, 8, EmberRetro.margemMoldura, 8,
          ),
          child: Column(
            children: [
              SizedBox(height: 54, child: top),
              const SizedBox(height: 14),
              Expanded(child: RetroPanel(padding: panelPadding, child: body)),
              if (ticker != null) ...[
                const SizedBox(height: 14),
                RetroTicker(text: ticker!),
              ],
              if (bottomNav != null) ...[
                const SizedBox(height: 14),
                bottomNav!,
                const SizedBox(height: 4),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// A "tela" interna com contorno, grade de fundo e régua no topo.
class RetroPanel extends StatelessWidget {
  const RetroPanel({super.key, required this.child, this.padding = EdgeInsets.zero, this.color, this.showGrid = true});

  final Widget child;
  final EdgeInsets padding;

  /// Padrão: RetroPalette.tela.
  final Color? color;
  final bool showGrid;

  @override
  Widget build(BuildContext context) {
    final p = RetroPalette.of(context);
    return Container(
      decoration: BoxDecoration(
        color: color ?? p.tela,
        border: p.contornoBorda,
        borderRadius: BorderRadius.circular(EmberRetro.raioTela),
      ),
      clipBehavior: Clip.antiAlias,
      child: CustomPaint(
        painter: showGrid ? _GridAndRulerPainter(grid: p.grade, ruler: p.regua) : null,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

class _GridAndRulerPainter extends CustomPainter {
  const _GridAndRulerPainter({required this.grid, required this.ruler});

  final Color grid;
  final Color ruler;

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = grid
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += EmberRetro.espacoGrade) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += EmberRetro.espacoGrade) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Régua no topo: traço menor a cada 8px, maior a cada 56px.
    const inset = 22.0;
    final minor = Paint()
      ..color = ruler.withAlpha(64)
      ..strokeWidth = 1.5;
    final major = Paint()
      ..color = ruler.withAlpha(128)
      ..strokeWidth = 2;
    var i = 0;
    for (double x = inset; x <= size.width - inset; x += 8, i++) {
      final isMajor = i % 7 == 0;
      canvas.drawLine(Offset(x, isMajor ? 7 : 9), Offset(x, isMajor ? 17 : 15), isMajor ? major : minor);
    }
  }

  @override
  bool shouldRepaint(covariant _GridAndRulerPainter old) => old.grid != grid || old.ruler != ruler;
}

/// Card com contorno e sombra dura.
class RetroCard extends StatelessWidget {
  const RetroCard({super.key, required this.child, this.padding = const EdgeInsets.all(14), this.color, this.onTap});

  final Widget child;
  final EdgeInsets padding;

  /// Padrão: RetroPalette.superficie.
  final Color? color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = RetroPalette.of(context);
    final card = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? p.superficie,
        border: p.contornoBorda,
        borderRadius: BorderRadius.circular(EmberRetro.raioCard),
        boxShadow: [p.sombraDeCard],
      ),
      child: child,
    );
    if (onTap == null) return card;
    return Semantics(button: true, child: GestureDetector(onTap: onTap, behavior: HitTestBehavior.opaque, child: card));
  }
}

enum RetroButtonShape { rounded, pill, circle }

/// Botão com volume: sombra sólida embaixo que "afunda" ao toque.
///
/// Sem `color`, usa o amarelo (sol) com texto escuro. Sem `foregroundColor`,
/// escolhe tinta sobre cores de marca e a cor de texto do tema sobre fundos do tema.
class RetroButton extends StatefulWidget {
  const RetroButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.color = EmberColors.sol,
    this.foregroundColor,
    this.height = 48,
    this.shape = RetroButtonShape.rounded,
    this.padding = const EdgeInsets.symmetric(horizontal: 18),
    this.semanticLabel,
    this.expand = false,
  });

  /// Botão quadrado/redondo só com ícone (46x46), como os cantos do topo.
  /// Sem `color`, usa RetroPalette.botaoSecundario.
  const RetroButton.icon({
    super.key,
    required this.onPressed,
    required Widget icon,
    required String this.semanticLabel,
    this.color,
    this.foregroundColor,
    this.shape = RetroButtonShape.rounded,
  })  : child = icon,
        height = 46,
        padding = EdgeInsets.zero,
        expand = false;

  final VoidCallback? onPressed;
  final Widget child;
  final Color? color;
  final Color? foregroundColor;
  final double height;
  final RetroButtonShape shape;
  final EdgeInsets padding;
  final String? semanticLabel;

  /// Ocupa toda a largura disponível.
  final bool expand;

  @override
  State<RetroButton> createState() => _RetroButtonState();
}

class _RetroButtonState extends State<RetroButton> {
  bool _down = false;

  void _setDown(bool value) {
    if (_down != value) setState(() => _down = value);
  }

  // Fundos claros/de marca: o texto em cima é sempre tinta.
  static final _fundosClaros = <Color>{
    EmberColors.sol,
    EmberColors.menta,
    EmberColors.lavanda,
    EmberColors.neblina,
    EmberColors.brasa,
    EmberColors.creme,
    EmberColors.branco,
  };

  @override
  Widget build(BuildContext context) {
    final p = RetroPalette.of(context);
    final bg = widget.color ?? p.botaoSecundario;
    final fg = widget.foregroundColor ?? (_fundosClaros.contains(bg) ? EmberColors.tinta : p.texto);

    final enabled = widget.onPressed != null;
    final depth = _down ? EmberRetro.profundidadePressionado : EmberRetro.profundidadeBotao;
    final isIconOnly = widget.padding == EdgeInsets.zero;

    final BorderRadius? radius = switch (widget.shape) {
      RetroButtonShape.rounded => BorderRadius.circular(EmberRetro.raioBotao),
      RetroButtonShape.pill => BorderRadius.circular(999),
      RetroButtonShape.circle => null,
    };

    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.semanticLabel,
      child: FocusableActionDetector(
        enabled: enabled,
        mouseCursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) => widget.onPressed?.call()),
        },
        child: GestureDetector(
          onTapDown: enabled ? (_) => _setDown(true) : null,
          onTapUp: enabled ? (_) => _setDown(false) : null,
          onTapCancel: () => _setDown(false),
          onTap: widget.onPressed,
          child: Padding(
            // reserva o espaço da sombra para o layout não pular
            padding: const EdgeInsets.only(bottom: EmberRetro.profundidadeBotao),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 80),
              curve: Curves.easeOut,
              height: widget.height,
              width: (isIconOnly || widget.shape == RetroButtonShape.circle)
                  ? widget.height
                  : (widget.expand ? double.infinity : null),
              padding: widget.padding,
              alignment: Alignment.center,
              transform: Matrix4.translationValues(0, EmberRetro.profundidadeBotao - depth, 0),
              decoration: BoxDecoration(
                color: enabled ? bg : bg.withAlpha(115),
                shape: widget.shape == RetroButtonShape.circle ? BoxShape.circle : BoxShape.rectangle,
                borderRadius: radius,
                border: p.contornoBorda,
                boxShadow: [BoxShadow(color: p.contorno, offset: Offset(0, depth))],
              ),
              child: IconTheme.merge(
                data: IconThemeData(color: fg, size: 20),
                child: DefaultTextStyle.merge(
                  style: EmberText.body(15, color: fg, weight: FontWeight.w800),
                  child: widget.child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Tag de status em pílula (VOTANDO / DECIDIDO / ENCERRADO).
class RetroTag extends StatelessWidget {
  const RetroTag(this.label, {super.key, this.color = EmberColors.sol});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: RetroPalette.of(context).contorno, width: 2),
      ),
      child: Text(label.toUpperCase(), style: EmberText.mono(10, color: EmberColors.tinta)),
    );
  }
}

/// Placa de título do topo: [TEXTO] (emblema) [TEXTO].
/// O emblema fica num círculo da cor de superfície; ícones dentro dele devem usar
/// RetroPalette.of(context).texto (ou só deixar o IconTheme padrão).
class RetroPlaque extends StatelessWidget {
  const RetroPlaque({super.key, required this.left, this.right = '', required this.emblem});

  /// Sem [right], vira a placa de nome único: (emblema) TEXTO — usada no login com "CHAMMA".
  final String left;
  final String right;
  final Widget emblem;

  @override
  Widget build(BuildContext context) {
    final p = RetroPalette.of(context);
    final single = right.isEmpty;
    final label = single
        ? EmberText.display(20, color: EmberColors.sol).copyWith(letterSpacing: 2.4)
        : EmberText.display(14, color: EmberColors.sol).copyWith(letterSpacing: 0.84);
    Widget emblemCircle(EdgeInsets margin) => Container(
          width: 44,
          height: 44,
          margin: margin,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: p.botaoSecundario,
            shape: BoxShape.circle,
            border: p.contornoBorda,
          ),
          child: IconTheme.merge(data: IconThemeData(color: p.texto), child: emblem),
        );
    return Semantics(
      header: true,
      label: '$left $right'.trim(),
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: EmberColors.tinta,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: p.contorno, width: EmberRetro.borda),
          ),
          child: Container(
            padding: single ? const EdgeInsets.only(left: 2, right: 18) : const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: EmberColors.lavanda, width: 2),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: single
                  ? [
                      emblemCircle(const EdgeInsets.only(right: 12, top: 2, bottom: 2)),
                      Text(left, style: label),
                    ]
                  : [
                      Text(left, style: label),
                      emblemCircle(const EdgeInsets.symmetric(horizontal: 10, vertical: 2)),
                      Text(right, style: label),
                    ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Letreiro que corre em loop, fundo tinta e texto "LED" amarelo.
class RetroTicker extends StatefulWidget {
  const RetroTicker({super.key, required this.text, this.pixelsPerSecond = 40});

  final String text;
  final double pixelsPerSecond;

  @override
  State<RetroTicker> createState() => _RetroTickerState();
}

class _RetroTickerState extends State<RetroTicker> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this);
  double _segmentWidth = 0;

  TextStyle get _style => EmberText.mono(13, color: EmberColors.sol).copyWith(
        shadows: const [Shadow(color: Color(0x80FFC43D), blurRadius: 8)],
      );

  void _configure(double segmentWidth, bool reduceMotion) {
    if (segmentWidth == _segmentWidth && (_controller.isAnimating || reduceMotion)) return;
    _segmentWidth = segmentWidth;
    _controller.duration = Duration(
      milliseconds: (segmentWidth / widget.pixelsPerSecond * 1000).round(),
    );
    if (reduceMotion) {
      _controller.stop();
    } else {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final painter = TextPainter(
      text: TextSpan(text: widget.text, style: _style),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    final segment = painter.width + 48; // 24px de respiro de cada lado
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _configure(segment, reduceMotion);
    });

    return Semantics(
      liveRegion: false,
      label: widget.text,
      child: ExcludeSemantics(
        child: Container(
          height: 40,
          decoration: BoxDecoration(
            color: EmberColors.tinta,
            borderRadius: BorderRadius.circular(999),
            border: RetroPalette.of(context).contornoBorda,
          ),
          clipBehavior: Clip.antiAlias,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final copies = math.max(2, (constraints.maxWidth / segment).ceil() + 1);
              return AnimatedBuilder(
                animation: _controller,
                builder: (context, child) => Transform.translate(
                  offset: Offset(-_controller.value * segment, 0),
                  child: child,
                ),
                child: OverflowBox(
                  alignment: Alignment.centerLeft,
                  maxWidth: double.infinity,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var i = 0; i < copies; i++)
                        SizedBox(
                          width: segment,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Text(widget.text, style: _style, maxLines: 1, softWrap: false),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Navegação inferior: botões com volume, o ativo em amarelo.
class RetroNavBar extends StatelessWidget {
  const RetroNavBar({super.key, required this.items, required this.currentIndex, required this.onSelect});

  final List<({IconData icon, String label})> items;
  final int currentIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final p = RetroPalette.of(context);
    return Row(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(width: 12),
          Expanded(
            child: RetroButton(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              color: i == currentIndex ? EmberColors.sol : p.botaoSecundario,
              foregroundColor: i == currentIndex ? EmberColors.tinta : p.texto,
              onPressed: () => onSelect(i),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(items[i].icon, size: 18),
                    const SizedBox(width: 7),
                    Text(
                      items[i].label,
                      style: EmberText.body(14, weight: i == currentIndex ? FontWeight.w800 : FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Status de um rolê → cor da tag, do pino no mapa etc.
enum RoleStatus {
  votando('Votando', EmberColors.brasa),
  decidido('Decidido', EmberColors.menta),
  encerrado('Encerrado', EmberColors.neblina);

  const RoleStatus(this.label, this.color);
  final String label;
  final Color color;
}

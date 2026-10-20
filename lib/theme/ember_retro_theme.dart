// Little Ember — estilo "Retrô sem pixel"
// Tokens + ThemeData + widgets base. Depende de: google_fonts
//
// Coloque em lib/theme/ember_retro_theme.dart e use:
//   MaterialApp(theme: EmberRetroTheme.light(), ...)

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ---------------------------------------------------------------------------
// TOKENS
// ---------------------------------------------------------------------------

abstract final class EmberColors {
  static const brasa = Color(0xFFFF5A4E); // moldura / "votando"
  static const brasaForte = Color(0xFFD9382E);
  static const brasaTexto = Color(0xFFB02A22); // texto vermelho sobre branco (contraste AA)
  static const sol = Color(0xFFFFC43D); // CTA principal / item ativo
  static const menta = Color(0xFF12B886); // "decidido" / "posso"
  static const lavanda = Color(0xFF8B7BFF); // "talvez" / detalhes da placa
  static const neblina = Color(0xFFB9B6C4); // "encerrado" / "não posso"
  static const creme = Color(0xFFFFF8F1); // fundo da tela interna
  static const branco = Color(0xFFFFFFFF); // cards e inputs
  static const tinta = Color(0xFF1B1A2E); // contornos, sombras e texto
  static const textoSecundario = Color(0xFF5E5B6E);
  static const linhaSuave = Color(0xFFEFE6DA); // divisores dentro de cards
  static const mapaTerra = Color(0xFFFBEBD6);
  static const mapaAgua = Color(0xFFBDE8DA);
  static const mapaParque = Color(0xFFCDEDD8);
  static const erroFundo = Color(0xFFFFE9E6); // fundo de caixas de erro

  // Dark mode
  static const noite = tinta;
  static const noiteSurface = Color(0xFF252438);
  static const noiteCard = Color(0xFF2F2E42);
  static const noiteBorda = Color(0xFF4A4860);
  static const noiteInput = Color(0xFF353348);
  static const noiteDivisor = Color(0xFF3D3B52);
  static const noiteGrid = Color(0x0DFFF8F1);
  static const noiteErroFundo = Color(0xFF3A2020);
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

  /// Sombra dura dos cards (tinta a 16%, sem blur).
  static const sombraCard = BoxShadow(
    color: Color(0x291B1A2E),
    offset: Offset(0, 6),
  );

  static Border get contorno => Border.all(color: EmberColors.tinta, width: borda);
}

abstract final class EmberText {
  /// Títulos e números de destaque.
  static TextStyle display(double size, {Color color = EmberColors.tinta}) =>
      GoogleFonts.bricolageGrotesque(
        fontSize: size,
        fontWeight: FontWeight.w800,
        height: 1.05,
        letterSpacing: -0.03 * size,
        color: color,
      );

  /// Rótulos em caixa alta, tags, letreiro (o ar de "painel de rastreador").
  static TextStyle mono(double size, {Color color = EmberColors.tinta}) =>
      GoogleFonts.spaceMono(
        fontSize: size,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.06 * size,
        color: color,
      );

  /// Corpo de texto.
  static TextStyle body(double size,
          {Color color = EmberColors.tinta, FontWeight weight = FontWeight.w500}) =>
      GoogleFonts.inter(fontSize: size, fontWeight: weight, color: color);
}

// ---------------------------------------------------------------------------
// THEME TOKENS (adaptáveis claro/escuro)
// ---------------------------------------------------------------------------

class RetroTokens extends ThemeExtension<RetroTokens> {
  const RetroTokens({
    required this.panelBg,
    required this.cardBg,
    required this.inputBg,
    required this.textPrimary,
    required this.textSecondary,
    required this.border,
    required this.shadow,
    required this.gridLine,
    required this.divider,
    required this.errorBg,
    required this.scaffoldBg,
  });

  final Color panelBg;
  final Color cardBg;
  final Color inputBg;
  final Color textPrimary;
  final Color textSecondary;
  final Color border;
  final Color shadow;
  final Color gridLine;
  final Color divider;
  final Color errorBg;
  final Color scaffoldBg;

  static const _light = RetroTokens(
    panelBg: EmberColors.creme,
    cardBg: EmberColors.branco,
    inputBg: EmberColors.branco,
    textPrimary: EmberColors.tinta,
    textSecondary: EmberColors.textoSecundario,
    border: EmberColors.tinta,
    shadow: Color(0x291B1A2E),
    gridLine: Color(0x0D1B1A2E),
    divider: EmberColors.linhaSuave,
    errorBg: EmberColors.erroFundo,
    scaffoldBg: EmberColors.brasa,
  );

  static const _dark = RetroTokens(
    panelBg: EmberColors.noiteSurface,
    cardBg: EmberColors.noiteCard,
    inputBg: EmberColors.noiteInput,
    textPrimary: EmberColors.creme,
    textSecondary: Color(0xFFB9B6C4),
    border: EmberColors.noiteBorda,
    shadow: Color(0x40000000),
    gridLine: EmberColors.noiteGrid,
    divider: EmberColors.noiteDivisor,
    errorBg: EmberColors.noiteErroFundo,
    scaffoldBg: EmberColors.tinta,
  );

  static RetroTokens light() => _light;
  static RetroTokens dark() => _dark;

  static RetroTokens of(BuildContext context) =>
      Theme.of(context).extension<RetroTokens>() ?? _light;

  @override
  RetroTokens copyWith({
    Color? panelBg,
    Color? cardBg,
    Color? inputBg,
    Color? textPrimary,
    Color? textSecondary,
    Color? border,
    Color? shadow,
    Color? gridLine,
    Color? divider,
    Color? errorBg,
    Color? scaffoldBg,
  }) =>
      RetroTokens(
        panelBg: panelBg ?? this.panelBg,
        cardBg: cardBg ?? this.cardBg,
        inputBg: inputBg ?? this.inputBg,
        textPrimary: textPrimary ?? this.textPrimary,
        textSecondary: textSecondary ?? this.textSecondary,
        border: border ?? this.border,
        shadow: shadow ?? this.shadow,
        gridLine: gridLine ?? this.gridLine,
        divider: divider ?? this.divider,
        errorBg: errorBg ?? this.errorBg,
        scaffoldBg: scaffoldBg ?? this.scaffoldBg,
      );

  @override
  RetroTokens lerp(covariant RetroTokens? other, double t) {
    if (other == null) return this;
    return RetroTokens(
      panelBg: Color.lerp(panelBg, other.panelBg, t)!,
      cardBg: Color.lerp(cardBg, other.cardBg, t)!,
      inputBg: Color.lerp(inputBg, other.inputBg, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      border: Color.lerp(border, other.border, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
      gridLine: Color.lerp(gridLine, other.gridLine, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      errorBg: Color.lerp(errorBg, other.errorBg, t)!,
      scaffoldBg: Color.lerp(scaffoldBg, other.scaffoldBg, t)!,
    );
  }
}

// ---------------------------------------------------------------------------
// THEME
// ---------------------------------------------------------------------------

abstract final class EmberRetroTheme {
  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: EmberColors.brasa,
      brightness: Brightness.light,
    ).copyWith(
      primary: EmberColors.sol,
      onPrimary: EmberColors.tinta,
      secondary: EmberColors.brasa,
      onSecondary: EmberColors.tinta,
      tertiary: EmberColors.lavanda,
      surface: EmberColors.creme,
      onSurface: EmberColors.tinta,
      outline: EmberColors.tinta,
      error: EmberColors.brasaForte,
    );

    final base = ThemeData(useMaterial3: true, colorScheme: scheme);
    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(EmberRetro.raioInput),
      borderSide: const BorderSide(color: EmberColors.tinta, width: EmberRetro.borda),
    );

    return base.copyWith(
      scaffoldBackgroundColor: EmberColors.brasa,
      textTheme: GoogleFonts.interTextTheme(base.textTheme)
          .apply(bodyColor: EmberColors.tinta, displayColor: EmberColors.tinta)
          .copyWith(
            headlineLarge: EmberText.display(34),
            headlineMedium: EmberText.display(30),
            titleLarge: EmberText.display(21),
            titleMedium: EmberText.display(17),
            bodyLarge: EmberText.body(16),
            bodyMedium: EmberText.body(14),
            labelLarge: EmberText.body(15, weight: FontWeight.w800),
            labelSmall: EmberText.mono(10),
          ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: EmberColors.branco,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        hintStyle: EmberText.body(16, color: EmberColors.textoSecundario),
        border: inputBorder,
        enabledBorder: inputBorder,
        focusedBorder: inputBorder.copyWith(
          borderSide: const BorderSide(color: EmberColors.lavanda, width: EmberRetro.borda),
        ),
        errorBorder: inputBorder.copyWith(
          borderSide: const BorderSide(color: EmberColors.brasaForte, width: EmberRetro.borda),
        ),
      ),
      dividerTheme: const DividerThemeData(color: EmberColors.linhaSuave, thickness: 2),
      splashFactory: NoSplash.splashFactory, // o "afundar" do botão substitui o ripple
      dialogTheme: DialogThemeData(
        backgroundColor: EmberColors.creme,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(EmberRetro.raioCard),
          side: const BorderSide(color: EmberColors.tinta, width: EmberRetro.borda),
        ),
        titleTextStyle: EmberText.display(22),
        contentTextStyle: EmberText.body(15),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: EmberColors.tinta,
          textStyle: EmberText.body(15, weight: FontWeight.w800),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: EmberColors.tinta,
        contentTextStyle: EmberText.body(14, color: EmberColors.creme, weight: FontWeight.w600),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(EmberRetro.raioBotao)),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: EmberColors.tinta),
      extensions: [RetroTokens.light()],
    );
  }

  static ThemeData dark() {
    final tokens = RetroTokens.dark();
    final scheme = ColorScheme.fromSeed(
      seedColor: EmberColors.brasa,
      brightness: Brightness.dark,
    ).copyWith(
      primary: EmberColors.sol,
      onPrimary: EmberColors.tinta,
      secondary: EmberColors.brasa,
      onSecondary: EmberColors.creme,
      tertiary: EmberColors.lavanda,
      surface: EmberColors.noiteSurface,
      onSurface: EmberColors.creme,
      outline: EmberColors.noiteBorda,
      error: EmberColors.brasaForte,
    );

    final base = ThemeData(useMaterial3: true, colorScheme: scheme);
    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(EmberRetro.raioInput),
      borderSide: BorderSide(color: tokens.border, width: EmberRetro.borda),
    );

    return base.copyWith(
      scaffoldBackgroundColor: tokens.scaffoldBg,
      textTheme: GoogleFonts.interTextTheme(base.textTheme)
          .apply(bodyColor: tokens.textPrimary, displayColor: tokens.textPrimary)
          .copyWith(
            headlineLarge: EmberText.display(34, color: tokens.textPrimary),
            headlineMedium: EmberText.display(30, color: tokens.textPrimary),
            titleLarge: EmberText.display(21, color: tokens.textPrimary),
            titleMedium: EmberText.display(17, color: tokens.textPrimary),
            bodyLarge: EmberText.body(16, color: tokens.textPrimary),
            bodyMedium: EmberText.body(14, color: tokens.textPrimary),
            labelLarge: EmberText.body(15, color: tokens.textPrimary, weight: FontWeight.w800),
            labelSmall: EmberText.mono(10, color: tokens.textSecondary),
          ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: tokens.inputBg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        hintStyle: EmberText.body(16, color: tokens.textSecondary),
        border: inputBorder,
        enabledBorder: inputBorder,
        focusedBorder: inputBorder.copyWith(
          borderSide: BorderSide(color: EmberColors.lavanda, width: EmberRetro.borda),
        ),
        errorBorder: inputBorder.copyWith(
          borderSide: BorderSide(color: EmberColors.brasaForte, width: EmberRetro.borda),
        ),
      ),
      dividerTheme: DividerThemeData(color: tokens.divider, thickness: 2),
      splashFactory: NoSplash.splashFactory,
      dialogTheme: DialogThemeData(
        backgroundColor: tokens.cardBg,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(EmberRetro.raioCard),
          side: BorderSide(color: tokens.border, width: EmberRetro.borda),
        ),
        titleTextStyle: EmberText.display(22, color: tokens.textPrimary),
        contentTextStyle: EmberText.body(15, color: tokens.textPrimary),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: tokens.textPrimary,
          textStyle: EmberText.body(15, color: tokens.textPrimary, weight: FontWeight.w800),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: EmberColors.creme,
        contentTextStyle: EmberText.body(14, color: EmberColors.tinta, weight: FontWeight.w600),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(EmberRetro.raioBotao)),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: tokens.textPrimary),
      extensions: [tokens],
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
    final tokens = RetroTokens.of(context);
    return Scaffold(
      backgroundColor: tokens.scaffoldBg,
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

/// A "tela" creme/escura com contorno, grade de fundo e régua no topo.
class RetroPanel extends StatelessWidget {
  const RetroPanel({super.key, required this.child, this.padding = EdgeInsets.zero, this.color, this.showGrid = true});

  final Widget child;
  final EdgeInsets padding;
  final Color? color;
  final bool showGrid;

  @override
  Widget build(BuildContext context) {
    final tokens = RetroTokens.of(context);
    final bg = color ?? tokens.panelBg;
    return Container(
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: tokens.border, width: EmberRetro.borda),
        borderRadius: BorderRadius.circular(EmberRetro.raioTela),
      ),
      clipBehavior: Clip.antiAlias,
      child: CustomPaint(
        painter: showGrid ? _GridAndRulerPainter(gridColor: tokens.gridLine, rulerColor: tokens.border) : null,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

class _GridAndRulerPainter extends CustomPainter {
  const _GridAndRulerPainter({required this.gridColor, required this.rulerColor});

  final Color gridColor;
  final Color rulerColor;

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += EmberRetro.espacoGrade) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (double y = 0; y < size.height; y += EmberRetro.espacoGrade) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    const inset = 22.0;
    final minor = Paint()
      ..color = rulerColor.withAlpha(102)
      ..strokeWidth = 1.5;
    final major = Paint()
      ..color = rulerColor.withAlpha(179)
      ..strokeWidth = 2;
    var i = 0;
    for (double x = inset; x <= size.width - inset; x += 8, i++) {
      final isMajor = i % 7 == 0;
      canvas.drawLine(Offset(x, isMajor ? 7 : 9), Offset(x, isMajor ? 17 : 15), isMajor ? major : minor);
    }
  }

  @override
  bool shouldRepaint(covariant _GridAndRulerPainter oldDelegate) =>
      gridColor != oldDelegate.gridColor || rulerColor != oldDelegate.rulerColor;
}

/// Card com contorno e sombra dura (adapta ao tema).
class RetroCard extends StatelessWidget {
  const RetroCard({super.key, required this.child, this.padding = const EdgeInsets.all(14), this.color, this.onTap});

  final Widget child;
  final EdgeInsets padding;
  final Color? color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = RetroTokens.of(context);
    final bg = color ?? tokens.cardBg;
    final card = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: tokens.border, width: EmberRetro.borda),
        borderRadius: BorderRadius.circular(EmberRetro.raioCard),
        boxShadow: [BoxShadow(color: tokens.shadow, offset: const Offset(0, 6))],
      ),
      child: child,
    );
    if (onTap == null) return card;
    return Semantics(button: true, child: GestureDetector(onTap: onTap, behavior: HitTestBehavior.opaque, child: card));
  }
}

enum RetroButtonShape { rounded, pill, circle }

/// Botão com volume: sombra sólida embaixo que "afunda" ao toque.
class RetroButton extends StatefulWidget {
  const RetroButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.color = EmberColors.sol,
    this.foregroundColor = EmberColors.tinta,
    this.height = 48,
    this.shape = RetroButtonShape.rounded,
    this.padding = const EdgeInsets.symmetric(horizontal: 18),
    this.semanticLabel,
    this.expand = false,
  });

  /// Botão quadrado/redondo só com ícone (46x46), como os cantos do topo.
  const RetroButton.icon({
    super.key,
    required this.onPressed,
    required Widget icon,
    required String this.semanticLabel,
    this.color = EmberColors.creme,
    this.foregroundColor = EmberColors.tinta,
    this.shape = RetroButtonShape.rounded,
  })  : child = icon,
        height = 46,
        padding = EdgeInsets.zero,
        expand = false;

  final VoidCallback? onPressed;
  final Widget child;
  final Color color;
  final Color foregroundColor;
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

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final depth = _down ? EmberRetro.profundidadePressionado : EmberRetro.profundidadeBotao;
    final isIconOnly = widget.padding == EdgeInsets.zero;
    final tokens = RetroTokens.of(context);

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
                color: enabled ? widget.color : widget.color.withAlpha(115),
                shape: widget.shape == RetroButtonShape.circle ? BoxShape.circle : BoxShape.rectangle,
                borderRadius: radius,
                border: Border.all(color: tokens.border, width: EmberRetro.borda),
                boxShadow: [BoxShadow(color: tokens.border, offset: Offset(0, depth))],
              ),
              child: IconTheme.merge(
                data: IconThemeData(color: widget.foregroundColor, size: 20),
                child: DefaultTextStyle.merge(
                  style: EmberText.body(15, color: widget.foregroundColor, weight: FontWeight.w800),
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
    final tokens = RetroTokens.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: tokens.border, width: 2),
      ),
      child: Text(label.toUpperCase(), style: EmberText.mono(10, color: tokens.textPrimary)),
    );
  }
}

/// Placa de título do topo: [TEXTO] (emblema) [TEXTO].
class RetroPlaque extends StatelessWidget {
  const RetroPlaque({super.key, required this.left, required this.right, required this.emblem});

  final String left;
  final String right;
  final Widget emblem;

  @override
  Widget build(BuildContext context) {
    final label = EmberText.display(14, color: EmberColors.sol).copyWith(letterSpacing: 0.84);
    return Semantics(
      header: true,
      label: '$left $right',
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: EmberColors.tinta,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: EmberColors.lavanda, width: 2),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(left, style: label),
                Container(
                  width: 44,
                  height: 44,
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: EmberColors.creme,
                    shape: BoxShape.circle,
                    border: EmberRetro.contorno,
                  ),
                  child: emblem,
                ),
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
            border: Border.all(color: RetroTokens.of(context).border, width: EmberRetro.borda),
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

/// Navegação inferior: 3 botões com volume, o ativo em amarelo.
class RetroNavBar extends StatelessWidget {
  const RetroNavBar({super.key, required this.items, required this.currentIndex, required this.onSelect});

  final List<({IconData icon, String label})> items;
  final int currentIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(width: 12),
          Expanded(
            child: RetroButton(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              color: i == currentIndex ? EmberColors.sol : EmberColors.creme,
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

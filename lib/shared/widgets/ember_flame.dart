import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../theme/ember_retro_theme.dart';

/// A chama do Little Ember (logo), vetorial. Substitui o emoji 🔥.
class EmberFlame extends StatelessWidget {
  const EmberFlame({
    super.key,
    this.size = 24,
    this.color = EmberColors.brasa,
    this.innerColor = EmberColors.sol,
    this.strokeWidth,
    this.semanticLabel,
  });

  /// Altura da chama; a largura é 80% disso.
  final double size;
  final Color color;
  final Color innerColor;

  /// Espessura do contorno em unidades do desenho (64x80). Padrão: mais grosso em tamanhos pequenos.
  final double? strokeWidth;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final flame = CustomPaint(
      size: Size(size * 0.8, size),
      painter: _FlamePainter(
        color: color,
        innerColor: innerColor,
        strokeWidth: strokeWidth ?? (size < 40 ? 5 : 3),
        withFace: false,
      ),
    );
    return semanticLabel == null
        ? ExcludeSemantics(child: flame)
        : Semantics(image: true, label: semanticLabel, child: flame);
  }
}

/// Brasinha: a chama com rostinho, mascote do app. Usada em login e estados vazios.
class Brasinha extends StatelessWidget {
  const Brasinha({super.key, this.size = 90, this.bob = true});

  final double size;

  /// Flutua de leve para cima e para baixo (desliga sozinho com "reduzir movimento").
  final bool bob;

  @override
  Widget build(BuildContext context) {
    Widget mascot = Semantics(
      image: true,
      label: 'Brasinha, o mascote do Little Ember',
      child: CustomPaint(
        size: Size(size * 0.8, size),
        painter: const _FlamePainter(
          color: EmberColors.brasa,
          innerColor: EmberColors.sol,
          strokeWidth: 3,
          withFace: true,
        ),
      ),
    );
    if (bob && !MediaQuery.of(context).disableAnimations) {
      mascot = mascot
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .moveY(begin: 0, end: -6, duration: 1200.ms, curve: Curves.easeInOut);
    }
    return mascot;
  }
}

class _FlamePainter extends CustomPainter {
  const _FlamePainter({
    required this.color,
    required this.innerColor,
    required this.strokeWidth,
    required this.withFace,
  });

  final Color color;
  final Color innerColor;
  final double strokeWidth;
  final bool withFace;

  static final Path _outer = Path()
    ..moveTo(32, 4)
    ..cubicTo(38, 18, 54, 28, 54, 48)
    ..cubicTo(54, 64, 44, 76, 32, 76)
    ..cubicTo(20, 76, 10, 64, 10, 48)
    ..cubicTo(10, 36, 18, 30, 22, 20)
    ..cubicTo(24, 30, 28, 32, 30, 32)
    ..cubicTo(30, 22, 28, 14, 32, 4)
    ..close();

  static final Path _inner = Path()
    ..moveTo(32, 40)
    ..cubicTo(37, 48, 42, 52, 42, 60)
    ..cubicTo(42, 67, 37, 72, 32, 72)
    ..cubicTo(27, 72, 22, 67, 22, 60)
    ..cubicTo(22, 52, 28, 48, 32, 40)
    ..close();

  static final Path _innerLow = Path()
    ..moveTo(32, 58)
    ..cubicTo(35, 62, 40, 64, 40, 68)
    ..cubicTo(40, 72, 36, 74, 32, 74)
    ..cubicTo(28, 74, 24, 72, 24, 68)
    ..cubicTo(24, 64, 29, 62, 32, 58)
    ..close();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 64, size.height / 80);

    final ink = Paint()
      ..color = EmberColors.tinta
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(_outer, Paint()..color = color);
    canvas.drawPath(withFace ? _innerLow : _inner, Paint()..color = innerColor);
    canvas.drawPath(_outer, ink);

    if (withFace) {
      final white = Paint()..color = EmberColors.branco;
      final pupil = Paint()..color = EmberColors.tinta;
      final faceInk = Paint()
        ..color = EmberColors.tinta
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round;
      for (final x in [24.0, 40.0]) {
        final eye = Rect.fromCenter(center: Offset(x, 42), width: 11, height: 13);
        canvas.drawOval(eye, white);
        canvas.drawOval(eye, faceInk);
        canvas.drawCircle(Offset(x + 1.5, 43.5), 2.6, pupil);
      }
      final cheek = Paint()..color = const Color(0xFFFFB4AC);
      canvas.drawCircle(const Offset(17, 50), 2.6, cheek);
      canvas.drawCircle(const Offset(47, 50), 2.6, cheek);
      canvas.drawPath(
        Path()
          ..moveTo(27, 52)
          ..quadraticBezierTo(32, 56.5, 37, 52),
        faceInk,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _FlamePainter old) =>
      old.color != color || old.innerColor != innerColor || old.strokeWidth != strokeWidth || old.withFace != withFace;
}

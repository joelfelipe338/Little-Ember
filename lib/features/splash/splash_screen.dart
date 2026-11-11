import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants.dart';
import '../../core/supabase/supabase_client.dart';
import '../../shared/widgets/ember_logo.dart';
import '../../theme/ember_retro_theme.dart';

/// Splash animada. Começa idêntica ao splash nativo (mesmo fundo, logo de 160pt
/// no centro) e então:
///   1. o ícone se encolhe e "pula" (squash & stretch) com uma balançadinha;
///   2. traços de "brilho" estouram em volta, como no ícone;
///   3. um halo quente pulsa atrás;
///   4. o nome e o slogan sobem;
///   5. tudo some e o app segue para a home (logado) ou para o login.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  static const _logoWidth = 160.0; // igual ao splash nativo
  late final AnimationController _c;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 2300))
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed) _goNext();
      });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    precacheImage(const AssetImage(EmberBrandAssets.logo), context);
    if (!_c.isAnimating && !_c.isCompleted) {
      if (MediaQuery.of(context).disableAnimations) {
        _c.duration = const Duration(milliseconds: 700);
      }
      _c.forward();
    }
  }

  void _goNext() {
    if (_navigated || !mounted) return;
    _navigated = true;
    final loggedIn = isRealUserSession();
    context.go(loggedIn ? '/' : '/login');
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  // Intervalos (0..1) da linha do tempo.
  double _seg(double t, double a, double b, [Curve curve = Curves.linear]) =>
      curve.transform(((t - a) / (b - a)).clamp(0.0, 1.0));

  @override
  Widget build(BuildContext context) {
    final p = RetroPalette.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final burstColor = dark ? EmberColors.sol : EmberColors.tinta;
    final titleColor = dark ? EmberColors.creme : EmberColors.tinta;

    return Scaffold(
      backgroundColor: p.moldura,
      body: Semantics(
        label: '${AppConstants.appName}. Carregando',
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            final t = _c.value;

            // 1. squash & stretch + balanço
            double scaleX = 1, scaleY = 1, angle = 0, lift = 0;
            if (!reduceMotion) {
              final squash = _seg(t, 0.00, 0.12, Curves.easeOut);     // agacha
              final jump = _seg(t, 0.12, 0.30, Curves.easeOutBack);   // estica/pula
              final land = _seg(t, 0.30, 0.48, Curves.elasticOut);    // assenta
              scaleX = 1 + 0.10 * squash - 0.16 * jump + 0.06 * land;
              scaleY = 1 - 0.14 * squash + 0.24 * jump - 0.10 * land;
              lift = -26 * jump * (1 - land);
              final wob = _seg(t, 0.25, 0.70);
              angle = math.sin(wob * math.pi * 3) * (1 - wob) * 0.16;
              // flutuação leve no final
              final idle = _seg(t, 0.70, 1.0);
              lift += -math.sin(idle * math.pi) * 6;
            }

            // 2. estouro de traços
            final burst = reduceMotion ? 0.0 : _seg(t, 0.26, 0.62, Curves.easeOutCubic);

            // 3. halo
            final halo = _seg(t, 0.20, 0.55, Curves.easeOut);
            final haloPulse = reduceMotion ? 0.0 : math.sin(_seg(t, 0.55, 1.0) * math.pi * 2) * 0.04;

            // 4. textos
            final title = _seg(t, 0.42, 0.66, Curves.easeOutCubic);
            final slogan = _seg(t, 0.52, 0.76, Curves.easeOutCubic);

            // 5. saída
            final exit = _seg(t, 0.88, 1.0, Curves.easeIn);

            const logoH = _logoWidth * EmberLogo.aspect;
            final logo = SizedBox(
              width: 300,
              height: 300,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Transform.scale(
                    scale: 0.6 + 0.6 * halo + haloPulse,
                    child: Opacity(
                      opacity: 0.55 * halo,
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: EmberColors.sol.withAlpha(dark ? 60 : 110),
                        ),
                      ),
                    ),
                  ),
                  if (burst > 0 && burst < 1)
                    CustomPaint(
                      size: const Size(300, 300),
                      painter: _BurstPainter(progress: burst, color: burstColor),
                    ),
                  Transform.translate(
                    offset: Offset(0, lift),
                    child: Transform.rotate(
                      angle: angle,
                      child: Transform(
                        alignment: Alignment.bottomCenter,
                        transform: Matrix4.diagonal3Values(scaleX, scaleY, 1),
                        child: const EmberLogo(width: _logoWidth, semanticLabel: null),
                      ),
                    ),
                  ),
                ],
              ),
            );

            final texts = Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Opacity(
                  opacity: title,
                  child: Transform.translate(
                    offset: Offset(0, 18 * (1 - title)),
                    child: Text(AppConstants.appName, style: EmberText.display(36, color: titleColor)),
                  ),
                ),
                const SizedBox(height: 10),
                Opacity(
                  opacity: slogan,
                  child: Transform.translate(
                    offset: Offset(0, 14 * (1 - slogan)),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: EmberColors.tinta,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        AppConstants.sloganCurto.toUpperCase(),
                        style: EmberText.mono(11, color: EmberColors.sol),
                      ),
                    ),
                  ),
                ),
              ],
            );

            // O logo fica exatamente no centro da tela (igual ao splash nativo);
            // os textos aparecem logo abaixo dele.
            return Opacity(
              opacity: 1 - exit,
              child: SizedBox.expand(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    logo,
                    Transform.translate(
                      offset: const Offset(0, logoH / 2 + 74),
                      child: texts,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Traços que estouram para fora, como os "brilhos" desenhados no ícone.
class _BurstPainter extends CustomPainter {
  _BurstPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    const count = 10;
    final fade = progress < 0.6 ? 1.0 : 1 - (progress - 0.6) / 0.4;
    final paint = Paint()
      ..color = color.withAlpha((255 * fade).round())
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < count; i++) {
      final a = -math.pi / 2 + i * 2 * math.pi / count + 0.2;
      final start = 92 + 40 * progress;
      final len = 18 * (1 - progress * 0.6);
      final dir = Offset(math.cos(a), math.sin(a));
      canvas.drawLine(c + dir * start, c + dir * (start + len), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _BurstPainter old) => old.progress != progress || old.color != color;
}

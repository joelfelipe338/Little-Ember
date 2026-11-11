import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Caminhos dos assets da marca (assets/images/branding/, com variações 2.0x e 3.0x).
abstract final class EmberBrandAssets {
  static const logo = 'assets/images/branding/logo_mark.png';
  static const logoSmall = 'assets/images/branding/logo_mark_small.png';
  static const appIcon = 'assets/images/branding/app_icon_rounded.png';
}

/// O ícone do app (calendário de óculos + chama), sem fundo.
/// Use no login, splash, estados vazios e no emblema da placa.
class EmberLogo extends StatelessWidget {
  const EmberLogo({super.key, this.width = 120, this.bob = false, this.semanticLabel = 'CHAMMA'});

  /// Largura em pontos. A altura segue a proporção da arte (~0,83).
  final double width;

  /// Flutua de leve para cima e para baixo (desliga com "reduzir movimento").
  final bool bob;
  final String? semanticLabel;

  static const aspect = 0.83; // altura / largura da arte

  @override
  Widget build(BuildContext context) {
    final asset = width <= 48 ? EmberBrandAssets.logoSmall : EmberBrandAssets.logo;
    Widget img = Image.asset(
      asset,
      width: width,
      height: width * aspect,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      semanticLabel: semanticLabel,
      excludeFromSemantics: semanticLabel == null,
    );
    if (bob && !MediaQuery.of(context).disableAnimations) {
      img = img
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .moveY(begin: 0, end: -6, duration: 1400.ms, curve: Curves.easeInOut);
    }
    return img;
  }
}

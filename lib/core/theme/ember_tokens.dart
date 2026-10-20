import 'package:flutter/material.dart';
import 'ember_colors.dart';

@immutable
class EmberTokens extends ThemeExtension<EmberTokens> {
  const EmberTokens({
    required this.posso,
    required this.talvez,
    required this.naoPosso,
    required this.brasa,
    required this.hardShadow,
    required this.cardBorder,
  });

  final Color posso;
  final Color talvez;
  final Color naoPosso;
  final Color brasa;
  final List<BoxShadow> hardShadow;
  final BorderSide cardBorder;

  static const light = EmberTokens(
    posso: EmberColors.menta,
    talvez: EmberColors.sol,
    naoPosso: EmberColors.neblina,
    brasa: EmberColors.brasa,
    hardShadow: [BoxShadow(color: EmberColors.noite, offset: Offset(3, 3))],
    cardBorder: BorderSide(color: EmberColors.noite, width: 2.5),
  );

  static const dark = EmberTokens(
    posso: EmberColors.menta,
    talvez: EmberColors.sol,
    naoPosso: Color(0xFF4A4860),
    brasa: EmberColors.brasa,
    hardShadow: [BoxShadow(color: Colors.black54, offset: Offset(3, 3))],
    cardBorder: BorderSide(color: Color(0xFF4A4860), width: 2),
  );

  @override
  EmberTokens copyWith({
    Color? posso,
    Color? talvez,
    Color? naoPosso,
    Color? brasa,
    List<BoxShadow>? hardShadow,
    BorderSide? cardBorder,
  }) =>
      EmberTokens(
        posso: posso ?? this.posso,
        talvez: talvez ?? this.talvez,
        naoPosso: naoPosso ?? this.naoPosso,
        brasa: brasa ?? this.brasa,
        hardShadow: hardShadow ?? this.hardShadow,
        cardBorder: cardBorder ?? this.cardBorder,
      );

  @override
  EmberTokens lerp(EmberTokens? other, double t) {
    if (other == null) return this;
    return EmberTokens(
      posso: Color.lerp(posso, other.posso, t)!,
      talvez: Color.lerp(talvez, other.talvez, t)!,
      naoPosso: Color.lerp(naoPosso, other.naoPosso, t)!,
      brasa: Color.lerp(brasa, other.brasa, t)!,
      hardShadow: other.hardShadow,
      cardBorder: BorderSide.lerp(cardBorder, other.cardBorder, t),
    );
  }
}

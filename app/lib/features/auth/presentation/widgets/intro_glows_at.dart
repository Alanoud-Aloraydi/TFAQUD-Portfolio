import 'dart:math' as math;

import 'package:app/features/auth/presentation/widgets/auth_intro.dart';
import 'package:app/features/auth/presentation/widgets/auth_intros.dart';
import 'package:flutter/widgets.dart';

/// The glows behind the pages, mixed between two pages while one slides
/// over the other. [page] is the page shown when [controller] has no
/// position yet.
(Color, Color) introGlowsAt(PageController controller, int page) {
  final double raw = controller.hasClients
      ? (controller.page ?? page.toDouble())
      : page.toDouble();
  final double at = raw.clamp(0, authIntros.length - 1).toDouble();
  final int from = at.floor();
  final int to = math.min(from + 1, authIntros.length - 1);
  final double t = at - from;
  final AuthIntro a = authIntros[from];
  final AuthIntro b = authIntros[to];
  return (
    Color.lerp(a.glowHigh, b.glowHigh, t) ?? a.glowHigh,
    Color.lerp(a.glowLow, b.glowLow, t) ?? a.glowLow,
  );
}

import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A card turned by a few degrees.
class IntroTurned extends StatelessWidget {
  const IntroTurned({super.key, required this.degrees, required this.child});

  final double degrees;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(angle: degrees * math.pi / 180, child: child);
  }
}

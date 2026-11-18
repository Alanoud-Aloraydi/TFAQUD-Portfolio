import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

/// [child] blurred by [sigma]; unchanged when the blur would not show.
Widget glassMenuBlurred(double sigma, Widget child) {
  if (sigma < 0.2) return child;
  return ImageFiltered(
    imageFilter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
    child: child,
  );
}

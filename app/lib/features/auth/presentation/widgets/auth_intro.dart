import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// One welcome page: the two soft glows behind it, and its words: the step
/// (نظّم، شارك، تابع), a title and one line.
class AuthIntro {
  const AuthIntro({
    required this.glowHigh,
    required this.glowLow,
    required this.stepKey,
    required this.titleKey,
    required this.bodyKey,
  });

  /// The glow at the top corner, and the one lower on the other side.
  final Color glowHigh;
  final Color glowLow;
  final String stepKey;
  final String titleKey;
  final String bodyKey;
}

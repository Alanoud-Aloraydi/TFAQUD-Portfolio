import 'package:app/features/auth/presentation/widgets/auth_glows.dart';
import 'package:app/features/auth/presentation/widgets/intro_glows_at.dart';
import 'package:flutter/material.dart';

/// The glows behind the welcome, following the pages as they slide.
class AuthMovingGlows extends StatelessWidget {
  const AuthMovingGlows({
    super.key,
    required this.controller,
    required this.page,
  });

  final PageController controller;
  final int page;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (BuildContext context, Widget? child) {
        final (Color high, Color low) = introGlowsAt(controller, page);
        return AuthGlows(high: high, low: low);
      },
    );
  }
}

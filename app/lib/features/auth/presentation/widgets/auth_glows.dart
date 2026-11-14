import 'package:app/features/auth/presentation/widgets/auth_glow.dart';
import 'package:flutter/material.dart';

/// Two soft round glows on the page: one at the top corner and one lower on
/// the other side, as on the pictures of the welcome.
class AuthGlows extends StatelessWidget {
  const AuthGlows({super.key, required this.high, required this.low});

  final Color high;
  final Color low;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        Positioned(
          top: 90,
          right: -60,
          child: AuthGlow(color: high, size: 300),
        ),
        Positioned(top: 300, left: -70, child: AuthGlow(color: low, size: 240)),
      ],
    );
  }
}

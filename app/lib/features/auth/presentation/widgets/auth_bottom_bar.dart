import 'package:app/core/theme/foundations/app_motion.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/features/auth/presentation/widgets/auth_controls.dart';
import 'package:app/features/auth/presentation/widgets/auth_start_block.dart';
import 'package:flutter/material.dart';

/// The bottom of the welcome, in reach of the thumb: «تخطي», the dots and
/// «التالي», or «ابدأ» on the last page.
class AuthBottomBar extends StatelessWidget {
  const AuthBottomBar({
    super.key,
    required this.count,
    required this.current,
    required this.onStart,
    required this.onNext,
  });

  final int count;
  final int current;
  final VoidCallback onStart;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: AnimatedSwitcher(
        duration: AppMotion.contentEnter,
        child: current == count - 1
            ? AuthStartBlock(
                key: const ValueKey<String>('start'),
                onStart: onStart,
              )
            : AuthControls(
                key: const ValueKey<String>('controls'),
                count: count,
                current: current,
                onSkip: onStart,
                onNext: onNext,
              ),
      ),
    );
  }
}

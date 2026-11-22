import 'package:app/core/theme/foundations/app_motion.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/legal/legal_links_note.dart';
import 'package:app/features/auth/presentation/widgets/intro_controls.dart';
import 'package:flutter/material.dart';

/// The bar under every page ([introControls]), and on the last page the
/// note on the terms under «ابدأ».
class IntroBar extends StatelessWidget {
  const IntroBar({
    super.key,
    required this.page,
    required this.total,
    required this.onSkip,
    required this.onNext,
  });

  /// From 1 to [total].
  final int page;
  final int total;
  final VoidCallback onSkip;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) => SafeArea(
    minimum: const EdgeInsets.all(AppSpacing.lg),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        AnimatedSwitcher(
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : AppMotion.contentEnter,
          child: introControls(
            context,
            page: page,
            total: total,
            onSkip: onSkip,
            onNext: onNext,
          ),
        ),
        // Hidden, not gone, so the bar keeps its size on every page.
        Visibility.maintain(
          visible: page == total,
          child: const LegalLinksNote(),
        ),
      ],
    ),
  );
}

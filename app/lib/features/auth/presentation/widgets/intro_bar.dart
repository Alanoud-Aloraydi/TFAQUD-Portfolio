import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_motion.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/legal/legal_links_note.dart';
import 'package:app/features/auth/presentation/widgets/intro_dots.dart';
import 'package:easy_localization/easy_localization.dart';
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

/// The welcome's buttons: «تخطي», the dots and «التالي»; on the last page
/// one wide «ابدأ» in their place, as the welcome before it had.
Widget introControls(
  BuildContext context, {
  required int page,
  required int total,
  required VoidCallback onSkip,
  required VoidCallback onNext,
}) {
  final ButtonStyle dark = FilledButton.styleFrom(
    backgroundColor: AppSemanticColors.textPrimary,
    foregroundColor: AppSemanticColors.surfaceContent,
    shape: const StadiumBorder(),
    // At least as wide as «التالي», as tall as every main button.
    minimumSize: const Size(120, AppSizes.button),
  );
  if (page == total) {
    return SizedBox(
      key: const ValueKey<String>('start'),
      width: double.infinity,
      child: FilledButton(
        onPressed: onNext,
        style: dark,
        child: Text(context.tr('auth.start')),
      ),
    );
  }
  return Row(
    key: const ValueKey<String>('next'),
    children: <Widget>[
      TextButton(onPressed: onSkip, child: Text(context.tr('intro.skip'))),
      Expanded(
        child: Center(
          child: IntroDots(page: page, total: total),
        ),
      ),
      FilledButton(
        onPressed: onNext,
        style: dark,
        child: Text(context.tr('intro.next')),
      ),
    ],
  );
}

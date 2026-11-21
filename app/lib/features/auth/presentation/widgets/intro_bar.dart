import 'package:app/core/l10n/spoken_arabic.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/layout/step_progress.dart';
import 'package:app/core/widgets/legal/legal_links_note.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The same bar under every page: «تخطي», the steps and «التالي». On the
/// last page «ابدأ» and the note on the terms; nothing else moves.
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
  Widget build(BuildContext context) {
    final bool last = page == total;
    final String skip = context.tr('intro.skip');
    final List<String> args = <String>['$page', '$total'];
    final String step = context.tr('common.step_of', args: args);
    // Hidden, not gone, so the bar keeps its size on every page.
    Widget kept(bool shown, Widget child) =>
        Visibility.maintain(visible: shown, child: child);
    return SafeArea(
      minimum: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            spacing: AppSpacing.md,
            children: <Widget>[
              kept(!last, TextButton(onPressed: onSkip, child: Text(skip))),
              Expanded(
                child: Semantics(
                  label: spoken(step),
                  child: StepProgress(step: page, total: total),
                ),
              ),
              FilledButton(
                onPressed: onNext,
                style: FilledButton.styleFrom(
                  backgroundColor: AppSemanticColors.textPrimary,
                  foregroundColor: AppSemanticColors.surfaceContent,
                  shape: const StadiumBorder(),
                  // One width for «التالي» and «ابدأ».
                  minimumSize: const Size(120, AppSizes.button),
                ),
                child: Text(context.tr(last ? 'auth.start' : 'intro.next')),
              ),
            ],
          ),
          kept(last, const LegalLinksNote()),
        ],
      ),
    );
  }
}

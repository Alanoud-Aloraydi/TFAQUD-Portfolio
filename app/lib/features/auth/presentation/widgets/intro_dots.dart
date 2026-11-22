import 'package:app/core/l10n/spoken_arabic.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_motion.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The welcome's pages as dots: the page on show is a longer dark bar, the
/// others short and light, so only one stands out. VoiceOver reads
/// «الخطوة 1 من 3».
class IntroDots extends StatelessWidget {
  const IntroDots({super.key, required this.page, required this.total});

  /// From 1 to [total].
  final int page;
  final int total;

  static const double _dot = 7;
  static const double _on = 24;

  @override
  Widget build(BuildContext context) {
    final Duration duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : AppMotion.contentEnter;
    final List<String> args = <String>['$page', '$total'];
    return Semantics(
      label: spoken(context.tr('common.step_of', args: args)),
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: AppSpacing.tight,
          children: <Widget>[
            for (int i = 1; i <= total; i++)
              AnimatedContainer(
                duration: duration,
                curve: AppMotion.easeOutCubic,
                width: i == page ? _on : _dot,
                height: _dot,
                decoration: ShapeDecoration(
                  color: i == page
                      ? AppSemanticColors.textPrimary
                      : AppSemanticColors.borderSubtle,
                  shape: const StadiumBorder(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

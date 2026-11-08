import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/theme/foundations/app_radius.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/features/circles/domain/entities/medical_file.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The yellow «!»: a honey circle with an exclamation mark. It marks a
/// medical file that still has unknown answers. The text next to it says
/// what is missing, so the color is never the only sign.
class AttentionMark extends StatelessWidget {
  const AttentionMark({super.key});

  static const double _size = AppSizes.icon;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        width: _size,
        height: _size,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: AppSemanticColors.accentWarm,
          shape: BoxShape.circle,
        ),
        child: Text(
          '!',
          style: Theme.of(context).textTheme.titleSmall
              ?.copyWith(color: AppSemanticColors.textPrimary, height: 1),
        ),
      ),
    );
  }
}

/// The words of the missing answers, joined: «فصيلة الدم، الأمراض المزمنة».
String medicalGapsText(BuildContext context, List<MedicalGap> gaps) {
  return gaps
      .map((MedicalGap gap) => context.tr('medical_alert.gap.${gap.name}'))
      .join(context.tr('medical_alert.separator'));
}

/// The box at the top of the medical file while answers are missing: the
/// yellow «!», «أكمل الملف الطبي», what is missing, and «أكمل الآن» that
/// opens the edit page.
class MedicalFileAlert extends StatelessWidget {
  const MedicalFileAlert({super.key, required this.gaps, this.onFill});

  final List<MedicalGap> gaps;

  /// Opens the edit page. Null hides the button (a reader who cannot edit).
  final VoidCallback? onFill;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final VoidCallback? fill = onFill;
    return Semantics(
      container: true,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.inset),
        decoration: ShapeDecoration(
          color: AppSemanticColors.surfaceAttention,
          shape: AppRadius.shape(
            AppRadius.m,
            side: const BorderSide(color: AppSemanticColors.borderAttention),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                const AttentionMark(),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    context.tr('medical_alert.title'),
                    style: text.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              context.tr(
                'medical_alert.missing',
                args: <String>[medicalGapsText(context, gaps)],
              ),
              style: text.bodySmall?.copyWith(
                color: context.tokens.warningText,
              ),
            ),
            if (fill != null) ...<Widget>[
              const SizedBox(height: AppSpacing.md),
              FilledButton.icon(
                onPressed: fill,
                style: FilledButton.styleFrom(
                  backgroundColor: AppSemanticColors.textPrimary,
                  foregroundColor: AppSemanticColors.surfaceContent,
                ),
                icon: const Icon(AppIcons.pencil, size: AppSizes.iconSmall),
                label: Text(context.tr('medical_alert.fill')),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

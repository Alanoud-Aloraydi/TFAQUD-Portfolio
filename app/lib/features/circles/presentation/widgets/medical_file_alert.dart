import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/theme/foundations/app_radius.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/features/circles/domain/entities/medical_file.dart';
import 'package:app/features/circles/domain/entities/medical_gap.dart';
import 'package:app/features/circles/presentation/widgets/medical_alert_title.dart';
import 'package:app/features/circles/presentation/widgets/medical_file_fill_button.dart';
import 'package:app/features/circles/presentation/widgets/medical_gaps_text.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

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
            const MedicalAlertTitle(),
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
              MedicalFileFillButton(onPressed: fill),
            ],
          ],
        ),
      ),
    );
  }
}

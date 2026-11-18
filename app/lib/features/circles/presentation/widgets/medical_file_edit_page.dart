import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/layout/content_switcher.dart';
import 'package:app/core/widgets/layout/step_header.dart';
import 'package:app/features/circles/presentation/cubit/medical_file_edit_state.dart';
import 'package:app/features/circles/presentation/widgets/medical_file_edit_content.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// The edit page of the medical file inside its frame: «رجوع» with the
/// title, and under it the content of the load [state].
class MedicalFileEditPage extends StatelessWidget {
  const MedicalFileEditPage({
    super.key,
    required this.state,
    required this.savedTo,
    required this.fileRoute,
  });

  final MedicalFileEditState state;

  /// Where «حفظ» goes; null returns to the page under this one.
  final String? savedTo;

  /// Where «رجوع» goes when there is no page under this one.
  final String fileRoute;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        StepHeader(
          title: context.tr('circles.file_edit_title'),
          onBack: context.canPop()
              ? () => context.pop()
              : () => context.go(fileRoute),
        ),
        const SizedBox(height: AppSpacing.lg),
        Expanded(
          // Loading, error and content fade into each other.
          child: ContentSwitcher(
            stateKey: state.status,
            child: MedicalFileEditContent(
              state: state,
              savedTo: savedTo,
              fileRoute: fileRoute,
            ),
          ),
        ),
      ],
    );
  }
}

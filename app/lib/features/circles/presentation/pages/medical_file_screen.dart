import 'package:app/app/router/routers.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/layout/content_switcher.dart';
import 'package:app/core/widgets/layout/info_row.dart';
import 'package:app/core/widgets/layout/settings_icon_tile.dart';
import 'package:app/core/widgets/pickers/birth_date_sheet.dart';
import 'package:app/features/circles/domain/entities/medical_file.dart';
import 'package:app/features/circles/presentation/cubit/medical_file_cubit.dart';
import 'package:app/features/circles/presentation/cubit/medical_file_state.dart';
import 'package:app/features/circles/presentation/widgets/attention_mark.dart';
import 'package:app/features/circles/presentation/widgets/medical_file_contacts.dart';
import 'package:app/features/circles/presentation/widgets/medical_file_edit_skeleton.dart';
import 'package:app/features/circles/presentation/widgets/medical_file_header.dart';
import 'package:app/features/circles/presentation/widgets/medical_file_skeleton.dart';
import 'package:app/features/circles/presentation/widgets/medical_texts.dart';
import 'package:app/features/circles/presentation/widgets/page_frame_padding.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// The medical file of a circle (CIRCLE-05): the patient's basic data and
/// health answers, and the emergency contacts, which are added, changed and
/// removed here. «تعديل» opens the edit page of the rest, and the page
/// needs a [MedicalFileCubit] above it.
class MedicalFileScreen extends StatelessWidget {
  const MedicalFileScreen({super.key, required this.circleId});

  final String circleId;

  /// Opens the edit page with the file this page already has, so it opens
  /// at once; «حفظ» there goes on to the circle tab.
  void _edit(BuildContext context, MedicalFileCubit cubit) {
    context.push(Routes.medicalFileEdit(circleId), extra: cubit.state.file);
  }

  @override
  Widget build(BuildContext context) {
    final MedicalFileCubit cubit = context.read<MedicalFileCubit>();
    return Scaffold(
      body: SafeArea(
        child: BlocConsumer<MedicalFileCubit, MedicalFileState>(
          listenWhen: (MedicalFileState before, MedicalFileState after) =>
              after.sessionEnded && !before.sessionEnded,
          listener: (BuildContext context, MedicalFileState state) =>
              context.go(Routes.auth),
          builder: (BuildContext context, MedicalFileState state) => Padding(
            padding: pageFramePadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                MedicalFileHeader(
                  canEdit: state.file != null,
                  onEdit: () => _edit(context, cubit),
                ),
                const SizedBox(height: AppSpacing.lg),
                Expanded(
                  // Loading, error and content fade into each other.
                  child: ContentSwitcher(
                    stateKey: state.status,
                    child: medicalFileBody(
                      context,
                      cubit: cubit,
                      state: state,
                      onEdit: () => _edit(context, cubit),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// What the medical file shows under its heading: the skeleton while it
/// loads, the reason it could not be loaded, else the answers and the
/// emergency contacts. [onEdit] opens the edit page.
Widget medicalFileBody(
  BuildContext context, {
  required MedicalFileCubit cubit,
  required MedicalFileState state,
  required VoidCallback onEdit,
}) => switch (state.status) {
  MedicalFileStatus.loading => const MedicalFileSkeleton(),
  MedicalFileStatus.failure => MedicalFileFailure(
    messageKey: state.messageKey,
    onRetry: cubit.load,
  ),
  MedicalFileStatus.ready => _ready(context, cubit, state, state.file!, onEdit),
};

Widget _ready(
  BuildContext context,
  MedicalFileCubit cubit,
  MedicalFileState state,
  MedicalFile file,
  VoidCallback onEdit,
) => ListView(
  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
  padding: const EdgeInsets.only(bottom: AppSpacing.xl),
  children: <Widget>[
    // A new circle has no medical answers yet: the yellow «!» says what is
    // missing and opens the edit page.
    if (file.needsFilling) ...<Widget>[
      MedicalFileAlert(gaps: file.gaps, onFill: onEdit),
      const SizedBox(height: AppSpacing.lg),
    ],
    MedicalFileFacts(file: file),
    const SizedBox(height: AppSpacing.xl),
    ...medicalFileContacts(context, cubit: cubit, file: file, form: state.form),
  ],
);

/// The saved answers of the medical file, one to a row.
class MedicalFileFacts extends StatelessWidget {
  const MedicalFileFacts({super.key, required this.file});

  final MedicalFile file;

  @override
  Widget build(BuildContext context) => SettingsCard(
    children: <Widget>[
      InfoRow(label: context.tr('circles.name'), value: file.patient.fullName),
      InfoRow(
        label: context.tr('circles.birth_date'),
        value: formatBirthDate(context, file.patient.birthDate),
      ),
      InfoRow(
        label: context.tr('circles.blood_type'),
        value: MedicalTexts.bloodType(context, file.profile.bloodType),
      ),
      InfoRow(
        label: context.tr('circles.allergies_title'),
        value: MedicalTexts.allergies(context, file.profile.allergies),
      ),
      InfoRow(
        label: context.tr('circles.conditions'),
        value: MedicalTexts.conditions(context, file.profile.conditions),
      ),
      InfoRow(label: context.tr('circles.city'), value: file.patient.city),
    ],
  );
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

/// The words of the missing answers, joined: «فصيلة الدم، الأمراض المزمنة».
String medicalGapsText(BuildContext context, List<MedicalGap> gaps) => gaps
    .map((MedicalGap gap) => context.tr('medical_alert.gap.${gap.name}'))
    .join(context.tr('medical_alert.separator'));

/// The yellow «!» and «أكمل الملف الطبي» beside it.
class MedicalAlertTitle extends StatelessWidget {
  const MedicalAlertTitle({super.key});

  @override
  Widget build(BuildContext context) => Row(
    children: <Widget>[
      const AttentionMark(),
      const SizedBox(width: AppSpacing.sm),
      Expanded(
        child: Text(
          context.tr('medical_alert.title'),
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
    ],
  );
}

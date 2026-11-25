import 'package:app/app/router/routers.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/layout/content_switcher.dart';
import 'package:app/core/widgets/layout/step_header.dart';
import 'package:app/features/circles/presentation/cubit/medical_file_edit_cubit.dart';
import 'package:app/features/circles/presentation/cubit/medical_file_edit_state.dart';
import 'package:app/features/circles/presentation/widgets/medical_file_edit_form.dart';
import 'package:app/features/circles/presentation/widgets/medical_file_edit_skeleton.dart';
import 'package:app/features/circles/presentation/widgets/medical_file_skeleton.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// The edit page of the medical file (CIRCLE-05, "تعديل"): the names of a
/// patient without an account, the birth date, the city, the blood type, the
/// chronic conditions and the allergies. Needs a [MedicalFileEditCubit] above
/// it. The detailed mode and the simplified mode open the same page, each
/// telling it where to go so that leaving it never changes the mode.
class MedicalFileEditScreen extends StatelessWidget {
  const MedicalFileEditScreen({
    super.key,
    this.savedTo = Routes.circle,
    this.closeTo,
  });

  /// Where «حفظ» goes: by default the circle tab, past the medical file
  /// page, where the patient card already shows what was saved. Null returns
  /// to the page under this one, which reads the file again.
  final String? savedTo;

  /// Where «رجوع» goes when there is no page under this one (an address
  /// opened on its own); by default the detailed mode's medical file.
  final String? closeTo;

  @override
  Widget build(BuildContext context) {
    final MedicalFileEditCubit cubit = context.read<MedicalFileEditCubit>();
    final String fileRoute = closeTo ?? Routes.medicalFile(cubit.circleId);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: BlocConsumer<MedicalFileEditCubit, MedicalFileEditState>(
            listenWhen: (
              MedicalFileEditState before,
              MedicalFileEditState after,
            ) => after.sessionEnded && !before.sessionEnded,
            listener: (BuildContext context, MedicalFileEditState state) =>
                context.go(Routes.auth),
            builder: (BuildContext context, MedicalFileEditState state) =>
                MedicalFileEditPage(
                  state: state,
                  savedTo: savedTo,
                  fileRoute: fileRoute,
                ),
          ),
        ),
      ),
    );
  }
}

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

/// What the edit page holds for one load [state] of the file: the skeleton,
/// the retry, or the form.
class MedicalFileEditContent extends StatelessWidget {
  const MedicalFileEditContent({
    super.key,
    required this.state,
    required this.savedTo,
    required this.fileRoute,
  });

  final MedicalFileEditState state;

  /// Where «حفظ» goes; null returns to the page under this one.
  final String? savedTo;

  /// The medical file page «رجوع» goes to when there is no page under this
  /// one.
  final String fileRoute;

  @override
  Widget build(BuildContext context) {
    switch (state.status) {
      case MedicalFileEditStatus.loading:
        return const MedicalFileEditSkeleton();
      case MedicalFileEditStatus.failure:
        return MedicalFileFailure(
          messageKey: state.messageKey,
          onRetry: context.read<MedicalFileEditCubit>().load,
        );
      case MedicalFileEditStatus.ready:
        return MedicalFileEditForm(
          state: state,
          savedTo: savedTo,
          fileRoute: fileRoute,
        );
    }
  }
}

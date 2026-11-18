import 'package:app/features/circles/presentation/cubit/medical_file_edit_cubit.dart';
import 'package:app/features/circles/presentation/cubit/medical_file_edit_state.dart';
import 'package:app/features/circles/presentation/widgets/medical_file_edit_form.dart';
import 'package:app/features/circles/presentation/widgets/medical_file_edit_skeleton.dart';
import 'package:app/features/circles/presentation/widgets/medical_file_failure.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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

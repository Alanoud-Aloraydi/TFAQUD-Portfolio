import 'package:app/app/router/routers.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/layout/content_switcher.dart';
import 'package:app/features/circles/presentation/cubit/medical_file_cubit.dart';
import 'package:app/features/circles/presentation/cubit/medical_file_state.dart';
import 'package:app/features/circles/presentation/widgets/medical_file_body.dart';
import 'package:app/features/circles/presentation/widgets/medical_file_header.dart';
import 'package:app/features/circles/presentation/widgets/page_frame_padding.dart';
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

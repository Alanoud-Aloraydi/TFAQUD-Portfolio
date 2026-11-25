import 'package:app/app/router/routers.dart';
import 'package:app/core/constants/app_icons.dart';
import 'package:app/features/circles/domain/entities/medical_file.dart';
import 'package:app/features/circles/presentation/cubit/medical_file_cubit.dart';
import 'package:app/features/circles/presentation/cubit/medical_file_state.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_file_body.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_page.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// «الملف الطبي» in the simplified mode: the patient's answers in big rows
/// and the people to call. «تعديل» opens the detailed mode's edit page
/// inside the simplified mode, and «حفظ» or «رجوع» there lands here again.
class SimplifiedMedicalFileScreen extends StatelessWidget {
  const SimplifiedMedicalFileScreen({super.key, required this.circleId});

  final String circleId;

  Future<void> _edit(BuildContext context, MedicalFile file) async {
    final MedicalFileCubit cubit = context.read<MedicalFileCubit>();
    await context.push<void>(
      Routes.simplifiedMedicalFileEdit(circleId),
      extra: file,
    );
    if (!cubit.isClosed) await cubit.load();
  }

  @override
  Widget build(BuildContext context) =>
      BlocConsumer<MedicalFileCubit, MedicalFileState>(
        listenWhen: (MedicalFileState before, MedicalFileState after) =>
            after.sessionEnded && !before.sessionEnded,
        listener: (BuildContext context, MedicalFileState state) =>
            context.go(Routes.auth),
        builder: (BuildContext context, MedicalFileState state) {
          final MedicalFile? file = state.file;
          return SimplifiedPage(
            title: context.tr('simplified_mode.file.title'),
            titleTrailing: file == null
                ? null
                : SimplifiedFileEditButton(
                    onPressed: () => _edit(context, file),
                  ),
            children: simplifiedFileBody(context, state),
          );
        },
      );
}

/// «✎ تعديل» beside the title, which opens the detailed mode's edit page
/// inside this mode. The pencil and the fill are the app's one edit
/// affordance (`EditAction`), at this mode's size.
class SimplifiedFileEditButton extends StatelessWidget {
  const SimplifiedFileEditButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => FilledButton.icon(
    onPressed: onPressed,
    icon: Icon(ActionIcons.pencil, size: SimplifiedStyle.caption),
    style: FilledButton.styleFrom(
      backgroundColor: SimplifiedColors.accentTint,
      foregroundColor: SimplifiedColors.ink,
      minimumSize: const Size(0, SimplifiedStyle.touch),
      shape: const StadiumBorder(),
      padding: const EdgeInsets.symmetric(horizontal: 24),
    ),
    label: Text(
      context.tr('simplified_mode.file.edit'),
      style: SimplifiedStyle.head(SimplifiedStyle.caption),
    ),
  );
}

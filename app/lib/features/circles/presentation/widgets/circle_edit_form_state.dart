import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/layout/inset_group.dart';
import 'package:app/core/widgets/layout/inset_text_row.dart';
import 'package:app/features/circles/presentation/cubit/circle_overview_cubit.dart';
import 'package:app/features/circles/presentation/cubit/circle_overview_state.dart';
import 'package:app/features/circles/presentation/widgets/circle_edit_form.dart';
import 'package:app/features/circles/presentation/widgets/circle_edit_photo.dart';
import 'package:app/features/circles/presentation/widgets/circle_name_saving.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The name typed in «تعديل الدائرة», and whether save was tapped with
/// none; the picture is saved on its own sheet, at once.
class CircleEditFormState extends State<CircleEditForm> with CircleNameSaving {
  @override
  late final TextEditingController nameField = TextEditingController(
    text: widget.name,
  );

  @override
  void dispose() {
    nameField.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      CircleEditPhoto(circleId: widget.circleId, overview: widget.overview),
      const SizedBox(height: AppSpacing.lg),
      InsetGroup(
        children: <Widget>[
          InsetTextRow(
            label: context.tr('circle_edit.name'),
            controller: nameField,
            maxLength: 60,
            textInputAction: TextInputAction.done,
            errorText: missingName ? context.tr('circle_edit.no_name') : null,
            onChanged: (_) {
              if (missingName) setState(() => missingName = false);
            },
          ),
        ],
      ),
      const SizedBox(height: AppSpacing.lg),
      BlocBuilder<CircleOverviewCubit, CircleOverviewState>(
        buildWhen: (before, after) => before.acting != after.acting,
        builder: (context, state) => FilledButton(
          onPressed: state.acting ? null : saveName,
          child: Text(context.tr('circle_edit.save')),
        ),
      ),
    ],
  );
}

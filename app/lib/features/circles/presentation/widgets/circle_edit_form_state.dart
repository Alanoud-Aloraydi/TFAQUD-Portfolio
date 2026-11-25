import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/feedback/app_toast.dart';
import 'package:app/core/widgets/layout/inset_group.dart';
import 'package:app/core/widgets/layout/inset_text_row.dart';
import 'package:app/features/circles/presentation/cubit/circle_overview_cubit.dart';
import 'package:app/features/circles/presentation/cubit/circle_overview_state.dart';
import 'package:app/features/circles/presentation/widgets/circle_edit_photo.dart';
import 'package:app/features/home/domain/usecases/home_use_case.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

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

/// Saving the circle's name from «تعديل الدائرة»: none is refused here;
/// the same name closes the sheet with nothing sent; a new one is sent,
/// the circle read again, and every list of circles told.
mixin CircleNameSaving on State<CircleEditForm> {
  TextEditingController get nameField;

  /// Save was tapped with no name.
  bool missingName = false;

  Future<void> saveName() async {
    final String name = nameField.text.trim();
    if (name.isEmpty) {
      setState(() => missingName = true);
      return;
    }
    final NavigatorState navigator = Navigator.of(context);
    // Read before the sheet closes, as the other sheets do.
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final String saved = context.tr('circle_edit.saved');
    if (name == widget.name.trim()) {
      navigator.pop();
      return;
    }
    final CircleOverviewCubit cubit = context.read<CircleOverviewCubit>();
    final String? failed = await cubit.act(
      () => cubit.circles.renameCircle(widget.circleId, name),
    );
    if (!mounted) return;
    if (failed != null) {
      AppToast.show(context, failed, kind: ToastKind.error);
      return;
    }
    GetIt.I<HomeUseCase>().notifyCirclesChanged();
    navigator.pop();
    AppToast.showText(messenger, saved);
  }
}

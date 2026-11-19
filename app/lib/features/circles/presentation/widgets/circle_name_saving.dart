import 'package:app/core/feedback/app_toast.dart';
import 'package:app/features/circles/presentation/cubit/circle_overview_cubit.dart';
import 'package:app/features/circles/presentation/widgets/circle_edit_form.dart';
import 'package:app/features/home/domain/use_cases/home_use_case.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

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

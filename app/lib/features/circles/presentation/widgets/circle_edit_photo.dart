import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/feedback/app_toast.dart';
import 'package:app/core/widgets/layout/inset_group.dart';
import 'package:app/core/widgets/layout/inset_text_row.dart';
import 'package:app/features/circles/domain/entities/circle_overview.dart';
import 'package:app/features/circles/presentation/cubit/circle_overview_cubit.dart';
import 'package:app/features/circles/presentation/cubit/circle_overview_state.dart';
import 'package:app/features/circles/presentation/widgets/edit_patient_photo.dart';
import 'package:app/features/circles/presentation/widgets/patient_city_field.dart';
import 'package:app/features/home/domain/usecases/home_use_case.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

/// The patient's picture at the top of «تعديل الدائرة», with «تغيير
/// الصورة» under it; a new one shows here and on the card at once.
class CircleEditPhoto extends StatelessWidget {
  const CircleEditPhoto({
    super.key,
    required this.circleId,
    required this.overview,
  });

  final String circleId;

  /// The circle as the sheet opened; the picture follows its reads.
  final CircleOverview overview;

  @override
  Widget build(BuildContext context) {
    final CircleOverviewCubit cubit = context.read<CircleOverviewCubit>();
    return BlocBuilder<CircleOverviewCubit, CircleOverviewState>(
      builder: (context, state) {
        final CircleOverview shown = state.overview ?? overview;
        return Column(
          children: <Widget>[
            PatientCardPhoto(circleId: circleId, overview: shown),
            TextButton.icon(
              onPressed: () => editPatientPhoto(
                context,
                circleId: circleId,
                overview: shown,
                onSaved: cubit.load,
              ),
              icon: const Icon(CupertinoIcons.camera),
              label: Text(context.tr('circle_edit.change_photo')),
            ),
          ],
        );
      },
    );
  }
}

/// What «تعديل الدائرة» holds: the patient's picture with «تغيير الصورة»,
/// the circle's name, and the save button.
class CircleEditForm extends StatefulWidget {
  const CircleEditForm({
    super.key,
    required this.circleId,
    required this.name,
    required this.overview,
  });

  final String circleId;

  /// The name the circle has now.
  final String name;
  final CircleOverview overview;

  @override
  State<CircleEditForm> createState() => CircleEditFormState();
}

/// The name typed in «تعديل الدائرة», and whether save was tapped with
/// none; the picture is saved on its own sheet, at once.
class CircleEditFormState extends State<CircleEditForm> {
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

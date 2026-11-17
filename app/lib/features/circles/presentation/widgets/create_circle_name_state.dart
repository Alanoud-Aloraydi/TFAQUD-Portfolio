import 'package:app/features/circles/presentation/circle_creation_finish.dart';
import 'package:app/features/circles/presentation/cubit/create_circle_cubit.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// What both circle-naming pages keep: the typed name, which lives as long
/// as the page does, and the tap that creates the circle.
mixin CreateCircleNameState<T extends StatefulWidget> on State<T> {
  late final TextEditingController customName = TextEditingController(
    text: context.read<CreateCircleCubit>().state.customName,
  );

  @override
  void dispose() {
    customName.dispose();
    super.dispose();
  }

  /// Creates the circle and opens it, with the chosen chip as its name.
  Future<void> create(CreateCircleCubit cubit) => createCircleAndOpen(
    context,
    cubit,
    presetName: context.tr('circles.preset.${cubit.state.namePreset.name}'),
  );
}

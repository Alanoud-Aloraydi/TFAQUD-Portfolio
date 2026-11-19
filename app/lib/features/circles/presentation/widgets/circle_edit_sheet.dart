import 'package:app/core/widgets/overlays/glass_sheet.dart';
import 'package:app/features/circles/domain/entities/circle_overview.dart';
import 'package:app/features/circles/presentation/cubit/circle_overview_cubit.dart';
import 'package:app/features/circles/presentation/widgets/circle_edit_form.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Opens «تعديل الدائرة» from the pen beside the circle's name: the
/// patient's picture and the circle's [name] together, for whoever may
/// change the picture.
Future<void> showCircleEditSheet(
  BuildContext context, {
  required String circleId,
  required String name,
  required CircleOverview overview,
}) {
  final CircleOverviewCubit cubit = context.read<CircleOverviewCubit>();
  return showGlassSheet<void>(
    context,
    title: context.tr('circle_edit.title'),
    builder: (_) => BlocProvider<CircleOverviewCubit>.value(
      value: cubit,
      child: CircleEditForm(circleId: circleId, name: name, overview: overview),
    ),
  );
}

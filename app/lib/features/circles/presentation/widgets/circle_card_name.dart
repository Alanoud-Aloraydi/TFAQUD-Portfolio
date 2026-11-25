import 'package:app/core/localization/spoken_arabic.dart';
import 'package:app/core/utils/birth_date_rules.dart';
import 'package:app/core/widgets/buttons/edit_action.dart';
import 'package:app/core/widgets/overlays/glass_menu_route.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/features/circles/domain/entities/circle_overview.dart';
import 'package:app/features/circles/presentation/cubit/circle_overview_cubit.dart';
import 'package:app/features/circles/presentation/widgets/circle_edit_photo.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The circle's name, with the one pen that edits it and the patient's
/// picture for whoever may change the picture, and under it who it cares
/// for: «نورة العتيبي، 72 سنة، بريدة».
class CircleCardName extends StatelessWidget {
  const CircleCardName({
    super.key,
    required this.circleId,
    required this.name,
    required this.overview,
  });

  final String circleId;
  final String name;
  final CircleOverview overview;

  String _who(BuildContext context) {
    final int age = BirthDateRules.ageOn(
      overview.patientBirthDate,
      PatientClockScope.of(context).today(),
    );
    return <String>[
      overview.patientName,
      context.tr('circle_overview.age', args: <String>['$age']),
      overview.city,
    ].join('، ');
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final String who = _who(context);
    return Semantics(
      header: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Flexible(child: Text(name, style: text.headlineMedium)),
              if (overview.canEditPatientPhoto)
                EditAction.pen(
                  tooltip: context.tr('circle_edit.title'),
                  onPressed: () => showCircleEditSheet(
                    context,
                    circleId: circleId,
                    name: name,
                    overview: overview,
                  ),
                ),
            ],
          ),
          Text(who, style: text.bodySmall, semanticsLabel: spoken(who)),
        ],
      ),
    );
  }
}

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

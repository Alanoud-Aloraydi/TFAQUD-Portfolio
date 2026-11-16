import 'package:app/core/l10n/spoken_arabic.dart';
import 'package:app/core/utils/birth_date_rules.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/features/circles/domain/entities/circle_overview.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The circle's name, and under it who it cares for:
/// «نورة العتيبي، 72 سنة، بريدة».
class CircleCardName extends StatelessWidget {
  const CircleCardName({super.key, required this.name, required this.overview});

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
          Text(name, style: text.headlineMedium),
          Text(who, style: text.bodySmall, semanticsLabel: spoken(who)),
        ],
      ),
    );
  }
}

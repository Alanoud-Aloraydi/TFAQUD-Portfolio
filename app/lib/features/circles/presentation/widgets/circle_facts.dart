import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/l10n/medical_texts.dart';
import 'package:app/features/circles/domain/entities/medical_profile_draft.dart';
import 'package:app/features/circles/presentation/widgets/circle_fact.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';

/// The three facts the circle card shows from the medical file: the blood
/// type, the allergies and the chronic conditions.
List<Widget> circleFacts(BuildContext context, MedicalProfileDraft profile) =>
    <Widget>[
      CircleFact(
        icon: CareIcons.drop,
        label: context.tr('circle_overview.blood_type'),
        value: MedicalTexts.bloodType(context, profile.bloodType),
      ),
      _allergies(context, profile.allergies),
      _conditions(context, profile.conditions),
    ];

/// «حساسية **البنسلين**», or only «لا توجد حساسية» when that was the answer.
Widget _allergies(BuildContext context, AllergiesDraft? allergies) =>
    CircleFact(
      icon: NoticeIcons.warning,
      label: allergies?.answer == ListAnswer.none
          ? null
          : context.tr('circle_overview.allergy'),
      value: MedicalTexts.allergies(context, allergies),
    );

/// «**السكري، الضغط**», «**لا أمراض مزمنة**», or «الأمراض المزمنة **غير
/// محدد**» when nobody answered.
Widget _conditions(BuildContext context, ConditionsDraft? conditions) {
  if (conditions == null) {
    return CircleFact(
      icon: CareIcons.heartbeat,
      label: context.tr('circle_overview.conditions'),
      value: MedicalTexts.conditions(context, conditions),
    );
  }
  return CircleFact(
    icon: CareIcons.heartbeat,
    value: conditions.answer == ListAnswer.none
        ? context.tr('circle_overview.no_conditions')
        : MedicalTexts.conditions(context, conditions),
  );
}

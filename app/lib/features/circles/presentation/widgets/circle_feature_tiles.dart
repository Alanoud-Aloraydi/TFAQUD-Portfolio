import 'package:app/app/router/routers.dart';
import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/localization/medical_texts.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/features/circles/domain/entities/medical_file.dart';
import 'package:app/features/circles/presentation/widgets/circle_fact.dart';
import 'package:app/features/circles/presentation/widgets/circle_feature_tile.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// The two tiles under the patient card, side by side and of one height:
/// the medical file and the emergency card.
class CircleFeatureTiles extends StatelessWidget {
  const CircleFeatureTiles({
    super.key,
    required this.circleId,
    required this.medicalFile,
  });

  final String circleId;
  final MedicalFile? medicalFile;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Expanded(
            child: CircleFeatureTile(
              icon: CareIcons.fileText,
              iconColor: AppSemanticColors.textSupporting,
              title: context.tr('circles.file_title'),
              // A file with unknown answers says so, with the yellow «!».
              subtitle: (medicalFile?.needsFilling ?? false)
                  ? context.tr('medical_alert.tile')
                  : context.tr('circle_overview.file_hint'),
              attention: medicalFile?.needsFilling ?? false,
              onTap: () => context.push(Routes.medicalFile(circleId)),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: CircleFeatureTile(
              icon: CareIcons.firstAid,
              iconColor: AppSemanticColors.statusError,
              title: context.tr('circles.card_title'),
              subtitle: context.tr('circle_overview.card_hint'),
              onTap: () => context.push(Routes.emergencyCard(circleId)),
            ),
          ),
        ],
      ),
    );
  }
}

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

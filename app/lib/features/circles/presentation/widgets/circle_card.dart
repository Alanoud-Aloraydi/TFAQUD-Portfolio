import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/l10n/medical_texts.dart';
import 'package:app/core/media/person_photo.dart';
import 'package:app/core/media/photo_edit_badge.dart';
import 'package:app/core/network/api_endpoints.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_radius.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/utils/birth_date_rules.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/features/circles/domain/entities/circle_overview.dart';
import 'package:app/features/circles/domain/entities/medical_file.dart';
import 'package:app/features/circles/domain/entities/medical_profile_draft.dart';
import 'package:app/features/circles/presentation/cubit/circle_overview_cubit.dart';
import 'package:app/features/circles/presentation/widgets/circle_app_mode_row.dart';
import 'package:app/features/circles/presentation/widgets/circle_fact.dart';
import 'package:app/features/home/domain/entities/home_entity.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The patient card: the circle's name, who it cares for, three facts from
/// the medical file, and the app mode the patient was given. A 2-point slate
/// edge, no shadow. The mode is shown only; it is set when the circle is
/// created. Without a [medicalFile] (it could not be read) the facts are
/// left out.
class CircleCard extends StatelessWidget {
  const CircleCard({
    super.key,
    required this.circle,
    required this.overview,
    required this.medicalFile,
  });

  final CareCircleSummary circle;
  final CircleOverview overview;
  final MedicalFile? medicalFile;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final MedicalProfileDraft? profile = medicalFile?.profile;
    return DecoratedBox(
      decoration: ShapeDecoration(
        color: AppSemanticColors.surfaceContent,
        shape: AppRadius.shape(
          AppRadius.l,
          side: const BorderSide(
            color: AppSemanticColors.textSupporting,
            width: AppSizes.borderEmphasis,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Semantics(
                  button: overview.canEditPatientPhoto,
                  label: context.tr(
                    'photos.patient_photo',
                    args: [overview.patientName],
                  ),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: overview.canEditPatientPhoto
                        ? () => showPersonPhotoSheet(
                            context,
                            title: context.tr(
                              'photos.patient_photo',
                              args: [overview.patientName],
                            ),
                            name: overview.patientName,
                            // A patient with their own account is one person
                            // with one photo: edit it through the account
                            // endpoint, so the circle tab and the profile
                            // stay in sync.
                            photoPath: overview.patientIsYou
                                ? ApiEndpoints.accountPhoto
                                : ApiEndpoints.patientPhoto(circle.id),
                            avatarPath: overview.patientIsYou
                                ? ApiEndpoints.accountAvatar
                                : ApiEndpoints.patientAvatar(circle.id),
                            avatarCode: overview.patientAvatarCode,
                            onSaved: context.read<CircleOverviewCubit>().load,
                          )
                        : null,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        PersonPhoto(
                          name: overview.patientName,
                          photoPath: overview.patientIsYou
                              ? ApiEndpoints.accountPhoto
                              : ApiEndpoints.patientPhoto(circle.id),
                          avatarCode: overview.patientAvatarCode,
                          size: AppSizes.avatarLarge,
                        ),
                        if (overview.canEditPatientPhoto)
                          const PhotoEditBadge(),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(circle.name, style: text.headlineMedium),
                        Text(_who(context), style: text.bodySmall),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (profile != null) ...<Widget>[
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: <Widget>[
                  CircleFact(
                    icon: AppIcons.drop,
                    label: context.tr('circle_overview.blood_type'),
                    value: MedicalTexts.bloodType(context, profile.bloodType),
                  ),
                  _allergyFact(context, profile.allergies),
                  _conditionsFact(context, profile.conditions),
                ],
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            const Divider(height: AppSizes.divider),
            const SizedBox(height: AppSpacing.md),
            if (overview.patientUsesApp)
              CircleAppModeRow(mode: overview.appMode)
            else
              Text(
                context.tr('circle_overview.profile_summary'),
                style: text.bodySmall,
              ),
          ],
        ),
      ),
    );
  }

  /// «نورة العتيبي · 72 سنة · بريدة».
  String _who(BuildContext context) {
    final int age = BirthDateRules.ageOn(
      overview.patientBirthDate,
      PatientClockScope.of(context).today(),
    );
    return <String>[
      overview.patientName,
      context.tr('circle_overview.age', args: <String>['$age']),
      overview.city,
    ].join(' · ');
  }

  /// «حساسية **البنسلين**», or only «لا توجد حساسية» when that was the
  /// answer.
  Widget _allergyFact(BuildContext context, AllergiesDraft? allergies) {
    final String value = MedicalTexts.allergies(context, allergies);
    return CircleFact(
      icon: AppIcons.warning,
      label: allergies?.answer == ListAnswer.none
          ? null
          : context.tr('circle_overview.allergy'),
      value: value,
    );
  }

  /// «**السكري، الضغط**», «**لا أمراض مزمنة**», or
  /// «الأمراض المزمنة **غير محدد**» when nobody answered.
  Widget _conditionsFact(BuildContext context, ConditionsDraft? conditions) {
    if (conditions == null) {
      return CircleFact(
        icon: AppIcons.heartbeat,
        label: context.tr('circle_overview.conditions'),
        value: MedicalTexts.conditions(context, conditions),
      );
    }
    return CircleFact(
      icon: AppIcons.heartbeat,
      value: conditions.answer == ListAnswer.none
          ? context.tr('circle_overview.no_conditions')
          : MedicalTexts.conditions(context, conditions),
    );
  }
}

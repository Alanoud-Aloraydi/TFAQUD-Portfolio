import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/localization/spoken_arabic.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/app_text_theme.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/utils/birth_date_rules.dart';
import 'package:app/core/widgets/buttons/edit_action.dart';
import 'package:app/core/widgets/overlays/glass_menu_route.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/features/circles/domain/entities/circle_app_mode.dart';
import 'package:app/features/circles/domain/entities/circle_overview.dart';
import 'package:app/features/circles/domain/entities/medical_file.dart';
import 'package:app/features/circles/presentation/cubit/circle_overview_cubit.dart';
import 'package:app/features/circles/presentation/widgets/circle_edit_photo.dart';
import 'package:app/features/circles/presentation/widgets/circle_feature_tiles.dart';
import 'package:app/features/circles/presentation/widgets/patient_city_field.dart';
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
  Widget build(BuildContext context) => DecoratedBox(
    decoration: ShapeDecoration(
      color: AppSemanticColors.surfaceContent,
      // No line around it: white on the page's grey is enough, and smooth.
      shape: AppRadius.shape(AppRadius.l),
    ),
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: circleCardContent(
          context,
          circleId: circle.id,
          circleName: circle.name,
          overview: overview,
          profile: medicalFile?.profile,
        ),
      ),
    ),
  );
}

/// What the patient card holds, in order: the picture beside the names, the
/// facts from the medical file when it could be read, and the app mode the
/// patient was given.
List<Widget> circleCardContent(
  BuildContext context, {
  required String circleId,
  required String circleName,
  required CircleOverview overview,
  required MedicalProfileDraft? profile,
}) => <Widget>[
  Row(
    children: <Widget>[
      PatientCardPhoto(circleId: circleId, overview: overview),
      const SizedBox(width: AppSpacing.md),
      Expanded(
        child: CircleCardName(
          circleId: circleId,
          name: circleName,
          overview: overview,
        ),
      ),
    ],
  ),
  if (profile != null) ...<Widget>[
    const SizedBox(height: AppSpacing.md),
    Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: circleFacts(context, profile),
    ),
  ],
  const SizedBox(height: AppSpacing.md),
  const Divider(height: AppSizes.divider),
  const SizedBox(height: AppSpacing.md),
  CircleAppModeRow(mode: overview.appMode, usesApp: overview.patientUsesApp),
];

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

/// «وضع التطبيق: **تفصيلي**», and under it why it cannot be changed here.
/// A patient who does not use the app says so in the same row and the same
/// words, rather than the row disappearing: the family still needs to know
/// why that person never signs in.
class CircleAppModeRow extends StatelessWidget {
  const CircleAppModeRow({
    super.key,
    required this.mode,
    required this.usesApp,
  });

  final CircleAppMode? mode;

  /// Whether the patient has an account of their own.
  final bool usesApp;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final String value = context.tr(
      !usesApp
          ? 'circle_overview.no_app'
          : mode == CircleAppMode.simplified
          ? 'circle_overview.simplified'
          : 'circle_overview.detailed',
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        CircleAppModeLine(value: value),
        Padding(
          padding: const EdgeInsetsDirectional.only(
            start: AppSizes.iconSmall + AppSpacing.sm,
          ),
          child: Text(
            context.tr(
              usesApp
                  ? 'circle_overview.mode_note'
                  : 'circle_overview.profile_summary',
            ),
            style: text.bodySmall,
          ),
        ),
      ],
    );
  }
}

/// «وضع التطبيق: **تفصيلي**» behind the card icon: the label in the
/// supporting colour, the [value] in the text's own.
class CircleAppModeLine extends StatelessWidget {
  const CircleAppModeLine({super.key, required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        const Icon(
          PeopleIcons.idCard,
          size: AppSizes.iconSmall,
          color: AppSemanticColors.textSupporting,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text.rich(
            TextSpan(
              children: <InlineSpan>[
                TextSpan(text: '${context.tr('circle_overview.app_mode')} '),
                TextSpan(
                  text: value,
                  style: const TextStyle(
                    color: AppSemanticColors.textPrimary,
                    fontWeight: AppTextTheme.semibold,
                  ),
                ),
              ],
            ),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}

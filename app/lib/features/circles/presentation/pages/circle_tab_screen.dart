import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/extensions/scroll_insets.dart';
import 'package:app/core/l10n/medical_texts.dart';
import 'package:app/core/media/person_photo.dart';
import 'package:app/core/media/private_photo.dart';
import 'package:app/core/media/private_photo_repository.dart';
import 'package:app/core/navigation/routers.dart';
import 'package:app/core/network/api_endpoints.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/app_text_theme.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/theme/foundations/app_radius.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/theme/materials/surface_style.dart';
import 'package:app/core/utils/arabic_digits.dart';
import 'package:app/core/utils/birth_date_rules.dart';
import 'package:app/core/utils/saudi_mobile.dart';
import 'package:app/core/widgets/feedback/status_pill.dart';
import 'package:app/core/widgets/forms/phone_field.dart';
import 'package:app/core/widgets/layout/large_title.dart';
import 'package:app/core/widgets/overlays/app_alert.dart';
import 'package:app/core/widgets/overlays/glass_sheet.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/features/circles/domain/circle_app_mode.dart';
import 'package:app/features/circles/domain/entities/circle_overview.dart';
import 'package:app/features/circles/domain/entities/medical_file.dart';
import 'package:app/features/circles/domain/entities/medical_profile_draft.dart';
import 'package:app/features/circles/domain/request_age.dart';
import 'package:app/features/circles/domain/use_cases/circles_use_case.dart';
import 'package:app/features/circles/presentation/cubit/circle_overview_cubit.dart';
import 'package:app/features/circles/presentation/widgets/medical_file_alert.dart';
import 'package:app/features/circles/presentation/widgets/member_profile_sheet.dart';
import 'package:app/features/home/domain/entities/home_entity.dart';
import 'package:app/features/home/presentation/cubit/home_cubit.dart';
import 'package:app/features/home/presentation/cubit/home_state.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

/// The "الدائرة" tab (CIRCLE-01): who the circle cares for and who shares
/// it. From the top: the patient card, the two tiles that open the medical
/// file and the emergency card, the members with the pending invitations,
/// «إضافة عضو» and «مغادرة الدائرة». Needs the [HomeCubit] of the home
/// screen above it.
class CircleTabScreen extends StatelessWidget {
  const CircleTabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeCubit, HomeState>(
      builder: (BuildContext context, HomeState state) {
        final String? selectedId = state.selectedCircleId;
        CareCircleSummary? circle;
        for (final CareCircleSummary candidate
            in state.data?.circles ?? const <CareCircleSummary>[]) {
          if (candidate.id == selectedId) circle = candidate;
        }
        if (circle == null) return const SizedBox.shrink();
        return BlocProvider(
          key: ValueKey(selectedId),
          create: (_) => CircleOverviewCubit(
            GetIt.I<CirclesUseCase>(),
            selectedId!,
            GetIt.I<PrivatePhotoRepository>().changes,
          )..load(),
          child: _CircleContent(circle: circle),
        );
      },
    );
  }
}

/// Renders the circle content element of circle tab screen.
class _CircleContent extends StatelessWidget {
  const _CircleContent({required this.circle});

  final CareCircleSummary circle;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CircleOverviewCubit, CircleOverviewState>(
      builder: (BuildContext context, CircleOverviewState state) => ListView(
        padding: context.scrollPadding(const EdgeInsets.all(AppSpacing.lg)),
        children: <Widget>[
          LargeTitle(
            title: context.tr('tab.circle'),
            subtitle: context.tr('circle_overview.subtitle'),
          ),
          if (state.status == CircleOverviewStatus.loading)
            const Center(child: CupertinoActivityIndicator())
          else if (state.status == CircleOverviewStatus.failure)
            Column(
              children: <Widget>[
                Text(
                  context.tr(state.errorKey ?? 'error.unknown'),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.lg),
                FilledButton(
                  onPressed: context.read<CircleOverviewCubit>().load,
                  child: Text(context.tr('auth.retry')),
                ),
              ],
            )
          else
            ..._ready(context, state),
        ],
      ),
    );
  }

  List<Widget> _ready(BuildContext context, CircleOverviewState state) {
    final CircleOverview overview = state.overview!;
    final MedicalFile? medicalFile = state.medicalFile;
    return <Widget>[
      CircleCard(circle: circle, overview: overview, medicalFile: medicalFile),
      const SizedBox(height: AppSpacing.md),
      IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Expanded(
              child: _CircleFeatureTile(
                icon: AppIcons.fileText,
                iconColor: AppSemanticColors.textSupporting,
                title: context.tr('circles.file_title'),
                // A file with unknown answers says so, with the yellow «!».
                subtitle: (medicalFile?.needsFilling ?? false)
                    ? context.tr('medical_alert.tile')
                    : context.tr('circle_overview.file_hint'),
                attention: medicalFile?.needsFilling ?? false,
                onTap: () => context.push(Routes.medicalFile(circle.id)),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _CircleFeatureTile(
                icon: AppIcons.firstAid,
                iconColor: AppSemanticColors.statusError,
                title: context.tr('circles.card_title'),
                subtitle: context.tr('circle_overview.card_hint'),
                onTap: () => context.push(Routes.emergencyCard(circle.id)),
              ),
            ),
          ],
        ),
      ),
      _MembersHeader(overview: overview),
      _MembersList(overview: overview, circleId: circle.id),
      if (overview.canManage) ...<Widget>[
        const SizedBox(height: AppSpacing.md),
        FilledButton.icon(
          onPressed: state.acting ? null : () => _invite(context),
          icon: const Icon(AppIcons.userPlus, size: AppSizes.iconSmall),
          label: Text(context.tr('circle_overview.add_member')),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextButton.icon(
          onPressed: state.acting ? null : () => _leave(context, overview),
          style: TextButton.styleFrom(
            foregroundColor: AppSemanticColors.statusError,
            minimumSize: const Size.fromHeight(AppSizes.button),
          ),
          icon: const Icon(AppIcons.signOut, size: AppSizes.iconSmall),
          label: Text(context.tr('circle_overview.leave')),
        ),
      ],
    ];
  }

  void _invite(BuildContext context) {
    final CircleOverviewCubit cubit = context.read<CircleOverviewCubit>();
    showGlassSheet<void>(
      context,
      title: context.tr('circle_overview.add_member'),
      message: context.tr('circle_overview.invite_hint'),
      builder: (_) => _InviteMemberSheet(cubit: cubit),
    );
  }

  Future<void> _leave(BuildContext context, CircleOverview overview) async {
    final bool deletesCircle = overview.leaveDeletesCircle;
    final bool? confirmed = await showAppAlert<bool>(
      context,
      title: context.tr(
        deletesCircle
            ? 'circle_overview.delete_title'
            : 'circle_overview.leave_title',
      ),
      message: context.tr(
        deletesCircle
            ? 'circle_overview.delete_message'
            : 'circle_overview.leave_message',
      ),
      actions: <AppAlertAction<bool>>[
        AppAlertAction<bool>(
          label: context.tr('circle_overview.cancel'),
          value: false,
        ),
        AppAlertAction<bool>(
          label: context.tr(
            deletesCircle
                ? 'circle_overview.delete_confirm'
                : 'circle_overview.leave',
          ),
          value: true,
          destructive: true,
        ),
      ],
    );
    if (confirmed != true || !context.mounted) return;
    final String? error = await context.read<CircleOverviewCubit>().leave(
      confirmDelete: deletesCircle,
    );
    if (!context.mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.tr(error))));
      return;
    }
    await context.read<HomeCubit>().refresh();
    if (context.mounted) context.go(Routes.today);
  }
}

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
                  _Fact(
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
              _AppMode(mode: overview.appMode)
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
    return _Fact(
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
      return _Fact(
        icon: AppIcons.heartbeat,
        label: context.tr('circle_overview.conditions'),
        value: MedicalTexts.conditions(context, conditions),
      );
    }
    return _Fact(
      icon: AppIcons.heartbeat,
      value: conditions.answer == ListAnswer.none
          ? context.tr('circle_overview.no_conditions')
          : MedicalTexts.conditions(context, conditions),
    );
  }
}

/// One fact on the patient card: a slate capsule with an outline icon, an
/// optional word and the value in ink.
class _Fact extends StatelessWidget {
  const _Fact({required this.icon, this.label, required this.value});

  final IconData icon;
  final String? label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final TextStyle? style = Theme.of(context).textTheme.bodySmall;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: const ShapeDecoration(
        color: AppSemanticColors.surfaceContent,
        shape: StadiumBorder(),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            icon,
            size: AppSizes.iconSmall,
            color: AppSemanticColors.textSupporting,
          ),
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Text.rich(
              TextSpan(
                children: <InlineSpan>[
                  if (label != null) TextSpan(text: '$label '),
                  TextSpan(
                    text: value,
                    style: const TextStyle(
                      color: AppSemanticColors.textPrimary,
                      fontWeight: AppTextTheme.semibold,
                    ),
                  ),
                ],
              ),
              style: style,
            ),
          ),
        ],
      ),
    );
  }
}

/// «وضع تطبيق المريض: **تفصيلي**», and under it why it cannot be changed
/// here.
class _AppMode extends StatelessWidget {
  const _AppMode({required this.mode});

  final CircleAppMode? mode;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final String value = context.tr(
      mode == CircleAppMode.simplified
          ? 'circle_overview.simplified'
          : 'circle_overview.detailed',
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            const Icon(
              AppIcons.idCard,
              size: AppSizes.iconSmall,
              color: AppSemanticColors.textSupporting,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: <InlineSpan>[
                    TextSpan(
                      text: '${context.tr('circle_overview.app_mode')} ',
                    ),
                    TextSpan(
                      text: value,
                      style: const TextStyle(
                        color: AppSemanticColors.textPrimary,
                        fontWeight: AppTextTheme.semibold,
                      ),
                    ),
                  ],
                ),
                style: text.bodySmall,
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsetsDirectional.only(
            start: AppSizes.iconSmall + AppSpacing.sm,
          ),
          child: Text(
            context.tr('circle_overview.mode_note'),
            style: text.bodySmall,
          ),
        ),
      ],
    );
  }
}

/// A tile under the patient card: an outline icon, its name and one line
/// on what it holds. Both tiles take the height of the taller one.
class _CircleFeatureTile extends StatelessWidget {
  const _CircleFeatureTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.attention = false,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  /// Something here waits to be filled: a honey tile with the yellow «!».
  final bool attention;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Semantics(
      button: true,
      label: '$title، $subtitle',
      excludeSemantics: true,
      onTap: onTap,
      child: Material(
        color: attention
            ? AppSemanticColors.surfaceAttention
            : AppSemanticColors.surfaceContent,
        shape: AppRadius.shape(
          AppRadius.m,
          side: attention
              ? const BorderSide(color: AppSemanticColors.borderAttention)
              : AppSurfaces.edge,
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Icon(icon, size: AppSizes.icon, color: iconColor),
                    if (attention) ...<Widget>[
                      const Spacer(),
                      const AttentionMark(),
                    ],
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(title, style: text.titleSmall),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  subtitle,
                  style: attention
                      ? text.bodySmall?.copyWith(
                          color: context.tokens.warningText,
                        )
                      : text.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// One switch per category (doses, measurements, appointments), each this
/// circle's own setting — someone in several circles may want only one
/// circle's appointments on their phone's calendar, say.
/// «الأعضاء», and at the end how many managers and pending invitations
/// there are: «3 مديرين · دعوة معلّقة».
class _MembersHeader extends StatelessWidget {
  const _MembersHeader({required this.overview});

  final CircleOverview overview;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final int invitations = overview.pendingInvitations.length;
    final String summary = <String>[
      _count(
        context,
        'managers',
        overview.members.where((member) => member.isManager).length,
      ),
      if (invitations > 0) _count(context, 'invitations', invitations),
    ].join(' · ');
    return Padding(
      padding: const EdgeInsets.only(
        top: AppSpacing.xl,
        bottom: AppSpacing.labelGap,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: <Widget>[
          Semantics(
            header: true,
            child: Text(
              context.tr('circle_overview.members'),
              style: text.headlineMedium,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              summary,
              textAlign: TextAlign.end,
              style: text.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  /// Arabic counting: «مدير واحد», «مديران», «3 مديرين», «11 مديرًا».
  /// The number is written 0-9.
  static String _count(BuildContext context, String noun, int count) {
    final String key = switch (count) {
      1 => 'one',
      2 => 'two',
      <= 10 => 'few',
      _ => 'many',
    };
    return context.tr('circle_overview.${noun}_$key', args: <String>['$count']);
  }
}

/// The members, then the pending invitations, in one slate group with
/// lines between the rows.
class _MembersList extends StatelessWidget {
  const _MembersList({required this.overview, required this.circleId});

  final CircleOverview overview;
  final String circleId;

  @override
  Widget build(BuildContext context) {
    final List<Widget> rows = <Widget>[
      for (final CircleMember member in overview.members)
        _MemberRow(
          member: member,
          circleId: circleId,
          patientUsesApp: overview.patientUsesApp,
          patientIsYou: overview.patientIsYou,
        ),
      for (final CirclePendingInvitation invitation
          in overview.pendingInvitations)
        _InvitationRow(invitation: invitation, canManage: overview.canManage),
    ];
    return DecoratedBox(
      decoration: ShapeDecoration(
        color: AppSemanticColors.surfaceContent,
        shape: AppRadius.shape(AppRadius.m, side: AppSurfaces.edge),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Column(
          children: <Widget>[
            for (int i = 0; i < rows.length; i++) ...<Widget>[
              if (i > 0)
                const Divider(
                  height: AppSizes.divider,
                  color: AppSemanticColors.borderPlan,
                ),
              rows[i],
            ],
          ],
        ),
      ),
    );
  }
}

/// An hourglass portrait for pending invitations.
class _Avatar extends StatelessWidget {
  const _Avatar.waiting();

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        width: AppSizes.avatar,
        height: AppSizes.avatar,
        alignment: Alignment.center,
        decoration: const ShapeDecoration(
          color: AppSemanticColors.surfaceAttention,
          shape: CircleBorder(),
        ),
        child: const Icon(
          AppIcons.hourglass,
          size: AppSizes.iconSmall,
          color: AppSemanticColors.doseDueMarker,
        ),
      ),
    );
  }
}

/// A member: the name with «أنت» for the viewer, «المريض · يستخدم التطبيق»
/// under the patient, and the badges «مدير» and «صاحب الملف» at the end.
class _MemberRow extends StatelessWidget {
  const _MemberRow({
    required this.member,
    required this.circleId,
    required this.patientUsesApp,
    required this.patientIsYou,
  });

  final CircleMember member;
  final String circleId;
  final bool patientUsesApp;
  final bool patientIsYou;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    // A patient with their own account is one person with one photo: read
    // it through the account endpoint, so the circle tab and the profile
    // stay in sync. The photo is only ever edited from the patient card or
    // the account page, never from this row.
    final String photoPath = member.isPatient
        ? (patientIsYou
              ? ApiEndpoints.accountPhoto
              : ApiEndpoints.patientPhoto(circleId))
        : personPhotoPath(circleId, member.accountId);
    return InkWell(
      // The viewer's own row opens their account; anyone else's opens that
      // member's card: photo, name and number, to call them.
      onTap: member.isYou
          ? () => context.push(Routes.account)
          : () => showMemberProfileSheet(
              context,
              member: member,
              photoPath: photoPath,
              patientUsesApp: patientUsesApp,
            ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Row(
          children: <Widget>[
            PersonPhoto(
              name: member.name,
              photoPath: photoPath,
              avatarCode: member.avatarCode,
              size: AppSizes.avatarPortrait,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Wrap(
                    spacing: AppSpacing.sm,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: <Widget>[
                      Text(member.name, style: text.titleSmall),
                      if (member.isYou) const _YouPill(),
                    ],
                  ),
                  if (member.isPatient && patientUsesApp)
                    Text(
                      context.tr('circle_overview.patient_line'),
                      style: text.bodySmall,
                    ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                if (member.isManager)
                  StatusPill(
                    text: context.tr('circle_overview.manager'),
                    background: AppSemanticColors.borderPlan,
                    foreground: AppSemanticColors.textSupporting,
                    icon: AppIcons.crown,
                  ),
                if (member.isPatient) ...<Widget>[
                  const SizedBox(height: AppSpacing.xs),
                  StatusPill(
                    text: context.tr('circle_overview.owner'),
                    background: AppSemanticColors.selectedSurface,
                    foreground: AppSemanticColors.statusSuccess,
                    icon: AppIcons.user,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// «أنت»: a small ink capsule after the viewer's name.
class _YouPill extends StatelessWidget {
  const _YouPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: const ShapeDecoration(
        color: AppSemanticColors.textPrimary,
        shape: StadiumBorder(),
      ),
      child: Text(
        context.tr('circle_overview.you'),
        style: Theme.of(context).textTheme.labelMedium
            ?.copyWith(color: AppSemanticColors.surfaceContent),
      ),
    );
  }
}

/// A pending invitation: the number left to right, how long ago it was
/// sent, and under them «إعادة الإرسال» and «إلغاء».
class _InvitationRow extends StatelessWidget {
  const _InvitationRow({required this.invitation, required this.canManage});

  final CirclePendingInvitation invitation;
  final bool canManage;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final CircleOverviewCubit cubit = context.read<CircleOverviewCubit>();
    // One change of the members at a time (CircleOverviewState.acting).
    final bool acting = context.select(
      (CircleOverviewCubit tab) => tab.state.acting,
    );
    final int days =
        RequestAge.days(invitation.sentAt, PatientClockScope.of(context)) ?? 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const _Avatar.waiting(),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  SaudiMobile.display(invitation.phoneNumber),
                  textDirection: TextDirection.ltr,
                  style: text.titleSmall,
                ),
                Text(
                  '${context.tr('circle_overview.pending')} · '
                  '${_sentText(context, days)}',
                  style: text.bodySmall,
                ),
                if (canManage)
                  Wrap(
                    spacing: AppSpacing.sm,
                    children: <Widget>[
                      _SmallAction(
                        label: context.tr('circle_overview.resend'),
                        color: AppSemanticColors.textPrimary,
                        enabled: !acting,
                        onPressed: () => _act(
                          context,
                          cubit.resendInvitation(invitation.id),
                        ),
                      ),
                      _SmallAction(
                        label: context.tr('circle_overview.cancel'),
                        color: AppSemanticColors.statusError,
                        enabled: !acting,
                        onPressed: () => _act(
                          context,
                          cubit.cancelInvitation(invitation.id),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// «أُرسلت اليوم», «أُرسلت قبل يومين», «أُرسلت قبل 5 أيام».
  static String _sentText(BuildContext context, int days) {
    if (days == 0) return context.tr('circle_overview.sent_today');
    if (days == 1) return context.tr('circle_overview.sent_yesterday');
    if (days == 2) return context.tr('circle_overview.sent_two_days');
    return context.tr(
      days <= 10
          ? 'circle_overview.sent_days_few'
          : 'circle_overview.sent_days_many',
      args: <String>['$days'],
    );
  }

  static Future<void> _act(BuildContext context, Future<String?> action) async {
    final String? errorKey = await action;
    if (!context.mounted || errorKey == null) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(context.tr(errorKey))));
  }
}

/// A small white capsule with a line edge (32 points high); its tap area is
/// 48 points.
class _SmallAction extends StatelessWidget {
  const _SmallAction({
    required this.label,
    required this.color,
    required this.onPressed,
    required this.enabled,
  });

  final String label;
  final Color color;
  final VoidCallback onPressed;

  /// False while another change of the members is on its way.
  final bool enabled;

  static const double _height = 32;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: enabled ? onPressed : null,
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        minimumSize: const Size(0, _height),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        tapTargetSize: MaterialTapTargetSize.padded,
        side: const BorderSide(color: AppSemanticColors.borderPlan),
        textStyle: Theme.of(context).textTheme.labelMedium,
      ),
      child: Text(label),
    );
  }
}

/// The sheet of «إضافة عضو»: the number and «إرسال الدعوة».
class _InviteMemberSheet extends StatefulWidget {
  const _InviteMemberSheet({required this.cubit});

  final CircleOverviewCubit cubit;

  @override
  State<_InviteMemberSheet> createState() => _InviteMemberSheetState();
}

class _InviteMemberSheetState extends State<_InviteMemberSheet> {
  final TextEditingController _phone = TextEditingController();
  String? _errorKey;
  bool _saving = false;

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_saving) return;
    setState(() => _saving = true);
    final String? error = await widget.cubit.invite(
      ArabicDigits.digitsOnly(_phone.text),
    );
    if (!mounted) return;
    if (error == null) {
      Navigator.of(context).pop();
    } else {
      setState(() {
        _saving = false;
        _errorKey = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        PhoneField(
          controller: _phone,
          autofocus: false,
          onChanged: (_) => setState(() => _errorKey = null),
          showError: _errorKey == 'circle_overview.phone_invalid',
        ),
        if (_errorKey != null)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Text(
              context.tr(_errorKey!),
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: AppSemanticColors.statusError),
            ),
          ),
        const SizedBox(height: AppSpacing.lg),
        FilledButton.icon(
          onPressed: _saving ? null : _send,
          style: FilledButton.styleFrom(
            backgroundColor: AppSemanticColors.textPrimary,
            foregroundColor: AppSemanticColors.surfaceContent,
            iconColor: AppSemanticColors.accentLeaf,
          ),
          icon: const Icon(AppIcons.paperPlane, size: AppSizes.iconSmall),
          label: Text(context.tr('circle_overview.send_invite')),
        ),
      ],
    );
  }
}

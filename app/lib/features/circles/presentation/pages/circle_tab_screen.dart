import 'package:app/core/extensions/scroll_insets.dart';
import 'package:app/core/navigation/routers.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_radius.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/utils/arabic_digits.dart';
import 'package:app/core/widgets/forms/phone_field.dart';
import 'package:app/core/widgets/overlays/app_alert.dart';
import 'package:app/core/widgets/layout/large_title.dart';
import 'package:app/features/home/domain/entities/home_entity.dart';
import 'package:app/features/home/presentation/cubit/home_cubit.dart';
import 'package:app/features/home/presentation/cubit/home_state.dart';
import 'package:app/features/circles/domain/entities/circle_overview.dart';
import 'package:app/features/circles/domain/entities/medical_file.dart';
import 'package:app/features/circles/domain/use_cases/circles_use_case.dart';
import 'package:app/features/circles/presentation/cubit/circle_overview_cubit.dart';
import 'package:app/features/circles/presentation/widgets/medical_texts.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:get_it/get_it.dart';

/// The "الدائرة" tab (CIRCLE-01). It shows the card of the selected circle
/// with the two buttons that open its medical file and its emergency card.
/// Needs the [HomeCubit] of the home screen above it.
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
          create: (_) =>
              CircleOverviewCubit(GetIt.I<CirclesUseCase>(), selectedId!)
                ..load(),
          child: _CircleContent(circle: circle),
        );
      },
    );
  }
}

class _CircleContent extends StatelessWidget {
  const _CircleContent({required this.circle});

  final CareCircleSummary circle;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CircleOverviewCubit, CircleOverviewState>(
      builder: (context, state) => ListView(
        padding: context.scrollPadding(const EdgeInsets.all(AppSpacing.lg)),
        children: <Widget>[
          LargeTitle(
            title: context.tr('tab.circle'),
            subtitle: context.tr('circle_overview.subtitle'),
          ),
          if (state.status == CircleOverviewStatus.loading)
            const Center(child: CupertinoActivityIndicator())
          else if (state.status == CircleOverviewStatus.failure)
            TextButton(
              onPressed: context.read<CircleOverviewCubit>().load,
              child: Text(context.tr(state.errorKey ?? 'error.unknown')),
            )
          else ...[
            CircleCard(
              circle: circle,
              overview: state.overview!,
              medicalFile: state.medicalFile!,
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: _CircleFeatureTile(
                    icon: CupertinoIcons.doc_text,
                    title: context.tr('circles.file_title'),
                    subtitle: context.tr('circle_overview.file_hint'),
                    onTap: () => context.push(Routes.medicalFile(circle.id)),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _CircleFeatureTile(
                    icon: CupertinoIcons.heart,
                    title: context.tr('circles.card_title'),
                    subtitle: context.tr('circle_overview.card_hint'),
                    onTap: () => context.push(Routes.emergencyCard(circle.id)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              context.tr('circle_overview.members'),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.md),
            _MembersCard(overview: state.overview!),
            if (state.overview!.canManage) ...[
              const SizedBox(height: AppSpacing.md),
              TextButton(
                onPressed: () => _leave(context, state.overview!),
                child: Text(
                  context.tr('circle_overview.leave'),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Future<void> _leave(BuildContext context, CircleOverview overview) async {
    final deletesCircle = overview.patientIsYou || overview.members.length == 1;
    final confirmed = await showAppAlert<bool>(
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
      actions: [
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
    final error = await context.read<CircleOverviewCubit>().leave(
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

/// The card of a circle: its name, and the buttons "الملف الطبي" and
/// "بطاقة الطوارئ".
class CircleCard extends StatelessWidget {
  const CircleCard({
    super.key,
    required this.circle,
    required this.overview,
    required this.medicalFile,
  });

  final CareCircleSummary circle;
  final CircleOverview overview;
  final MedicalFile medicalFile;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final String name = overview.name.trim();
    final String initial = name.isEmpty
        ? ''
        : String.fromCharCode(name.runes.first);
    final today = DateTime.now();
    final birth = overview.patientBirthDate;
    final age =
        today.year -
        birth.year -
        ((today.month < birth.month ||
                (today.month == birth.month && today.day < birth.day))
            ? 1
            : 0);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppSemanticColors.surfaceContent,
        border: Border.all(color: AppSemanticColors.textSupporting),
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              ExcludeSemantics(
                child: CircleAvatar(
                  radius: 24,
                  backgroundColor: AppSemanticColors.selectedSurface,
                  child: Text(
                    initial,
                    style: text.titleLarge?.copyWith(
                      color: AppSemanticColors.textPrimary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Semantics(
                  header: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(circle.name, style: text.headlineSmall),
                      Text(
                        '${overview.patientName} · '
                        '${context.tr('circle_overview.age', args: ['$age'])} · '
                        '${overview.city}',
                        style: text.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              Chip(
                label: Text(
                  MedicalTexts.bloodType(
                    context,
                    medicalFile.profile.bloodType,
                  ),
                ),
                avatar: const Icon(CupertinoIcons.drop),
              ),
              Chip(
                label: Text(
                  MedicalTexts.allergies(
                    context,
                    medicalFile.profile.allergies,
                  ),
                ),
                avatar: const Icon(CupertinoIcons.exclamationmark_triangle),
              ),
              Chip(
                label: Text(
                  MedicalTexts.conditions(
                    context,
                    medicalFile.profile.conditions,
                  ),
                ),
                avatar: const Icon(CupertinoIcons.heart),
              ),
            ],
          ),
          const Divider(height: AppSpacing.xl),
          Text(
            overview.patientUsesApp
                ? context.tr(
                    'circle_overview.app_mode',
                    args: [
                      context.tr(
                        overview.appMode == 'simplified'
                            ? 'circle_overview.simplified'
                            : 'circle_overview.detailed',
                      ),
                    ],
                  )
                : context.tr('circle_overview.profile_summary'),
            style: text.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _CircleFeatureTile extends StatelessWidget {
  const _CircleFeatureTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: AppSemanticColors.surfacePlan,
    borderRadius: BorderRadius.circular(AppRadius.card),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Icon(icon),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(title, textAlign: TextAlign.center),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    ),
  );
}

class _MembersCard extends StatelessWidget {
  const _MembersCard({required this.overview});

  final CircleOverview overview;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: AppSemanticColors.surfacePlan,
      borderRadius: BorderRadius.circular(AppRadius.card),
    ),
    child: Column(
      children: [
        for (final member in overview.members)
          ListTile(
            leading: CircleAvatar(
              child: Text(member.name.isEmpty ? '؟' : member.name[0]),
            ),
            title: Text(member.name),
            subtitle: Text(context.tr('circle_overview.manager')),
            trailing: member.isYou
                ? Text(context.tr('circle_overview.you'))
                : null,
          ),
        for (final invitation in overview.pendingInvitations)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ListTile(
                leading: const Icon(CupertinoIcons.hourglass),
                title: Text(
                  invitation.phoneNumber,
                  textDirection: TextDirection.ltr,
                  textAlign: TextAlign.right,
                ),
                subtitle: Text(context.tr('circle_overview.pending')),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => _act(
                      context,
                      context.read<CircleOverviewCubit>().resendInvitation(
                        invitation.id,
                      ),
                    ),
                    child: Text(context.tr('circle_overview.resend')),
                  ),
                  TextButton(
                    onPressed: () => _act(
                      context,
                      context.read<CircleOverviewCubit>().cancelInvitation(
                        invitation.id,
                      ),
                    ),
                    child: Text(context.tr('circle_overview.cancel')),
                  ),
                ],
              ),
            ],
          ),
        if (overview.canManage)
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: FilledButton.icon(
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                showDragHandle: true,
                builder: (_) => _InviteMemberSheet(
                  cubit: context.read<CircleOverviewCubit>(),
                ),
              ),
              icon: const Icon(CupertinoIcons.person_add),
              label: Text(context.tr('circle_overview.add_member')),
            ),
          ),
      ],
    ),
  );

  Future<void> _act(BuildContext context, Future<String?> action) async {
    final errorKey = await action;
    if (!context.mounted || errorKey == null) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(context.tr(errorKey))));
  }
}

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
    final error = await widget.cubit.invite(
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
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.lg + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            context.tr('circle_overview.add_member'),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            context.tr('circle_overview.invite_hint'),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          PhoneField(
            controller: _phone,
            autofocus: false,
            onChanged: (_) => setState(() => _errorKey = null),
            showError: _errorKey == 'circle_overview.phone_invalid',
          ),
          if (_errorKey != null)
            Text(
              context.tr(_errorKey!),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton(
            onPressed: _saving ? null : _send,
            child: Text(context.tr('circle_overview.send_invite')),
          ),
        ],
      ),
    ),
  );
}

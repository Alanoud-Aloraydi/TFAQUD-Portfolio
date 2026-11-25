import 'package:app/app/router/routers.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/feedback/app_toast.dart';
import 'package:app/core/widgets/layout/content_switcher.dart';
import 'package:app/core/widgets/layout/inset_text.dart';
import 'package:app/core/widgets/layout/step_header.dart';
import 'package:app/core/widgets/navigation/glass_segmented_control.dart';
import 'package:app/features/circles/presentation/cubit/create_circle_cubit.dart';
import 'package:app/features/circles/presentation/cubit/create_circle_state.dart';
import 'package:app/features/circles/presentation/cubit/inbox_cubit.dart';
import 'package:app/features/circles/presentation/cubit/inbox_state.dart';
import 'package:app/features/circles/presentation/widgets/account_load_failed.dart';
import 'package:app/features/circles/presentation/widgets/circle_basics_fields.dart';
import 'package:app/features/circles/presentation/widgets/circle_basics_scaffold.dart';
import 'package:app/features/circles/presentation/widgets/circle_name_chips.dart';
import 'package:app/features/circles/presentation/widgets/create_circle_name_state.dart';
import 'package:app/features/circles/presentation/widgets/notifications_content.dart';
import 'package:app/features/circles/presentation/widgets/notifications_empty.dart';
import 'package:app/features/circles/presentation/widgets/read_only_field.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// The notifications page, in two tabs: what needs an answer, and what was
/// answered in the last 30 days. Needs an [InboxCubit] above it.
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final InboxCubit cubit = context.read<InboxCubit>();
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            0,
          ),
          child: BlocConsumer<InboxCubit, InboxState>(
            listenWhen: (InboxState before, InboxState after) =>
                (after.sessionEnded && !before.sessionEnded) ||
                (after.errorKey != null && after.errorKey != before.errorKey),
            listener: _listen,
            builder: (BuildContext context, InboxState state) =>
                NotificationsBody(cubit: cubit, state: state),
          ),
        ),
      ),
    );
  }

  void _listen(BuildContext context, InboxState state) {
    if (state.sessionEnded) return context.go(Routes.auth);
    final String? key = state.errorKey;
    if (key == null) return;
    AppToast.show(context, key, kind: ToastKind.error);
    context.read<InboxCubit>().errorShown();
  }
}

/// The header, the two tabs, and the content that fits the load [state].
/// The page opens on the tab [NotificationsTab.startFor] picks.
class NotificationsBody extends StatefulWidget {
  const NotificationsBody({
    super.key,
    required this.cubit,
    required this.state,
  });

  final InboxCubit cubit;
  final InboxState state;

  @override
  State<NotificationsBody> createState() => _NotificationsBodyState();
}

class _NotificationsBodyState extends State<NotificationsBody> {
  late NotificationsTab _tab = NotificationsTab.startFor(widget.state.inbox);

  @override
  Widget build(BuildContext context) {
    final InboxState state = widget.state;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        StepHeader(
          title: context.tr('topbar.notifications'),
          // The page is a modal: the close button takes it down.
          onClose: context.canPop()
              ? () => context.pop()
              : () => context.go(Routes.today),
        ),
        const SizedBox(height: AppSpacing.md),
        NotificationsTabs(
          selected: _tab,
          needsReply: state.inbox.needsReply,
          onChanged: (NotificationsTab tab) => setState(() => _tab = tab),
        ),
        const SizedBox(height: AppSpacing.lg),
        Expanded(
          child: ContentSwitcher(
            stateKey: (state.status, _tab),
            child: NotificationsContent(
              cubit: widget.cubit,
              state: state,
              tab: _tab,
            ),
          ),
        ),
      ],
    );
  }
}

/// The two tabs of the notifications page, «الحالية» and «السابقة».
class NotificationsTabs extends StatelessWidget {
  const NotificationsTabs({
    super.key,
    required this.selected,
    required this.needsReply,
    required this.onChanged,
  });

  final NotificationsTab selected;
  final int needsReply;
  final ValueChanged<NotificationsTab> onChanged;

  @override
  Widget build(BuildContext context) {
    return GlassSegmentedControl<NotificationsTab>(
      segments: <NotificationsTab, String>{
        NotificationsTab.current: context.tr('circles.tab_current'),
        NotificationsTab.previous: context.tr('circles.tab_previous'),
      },
      // How many wait for an answer, beside «الحالية».
      counts: needsReply == 0
          ? null
          : <NotificationsTab, int>{NotificationsTab.current: needsReply},
      selected: selected,
      onChanged: onChanged,
    );
  }
}

/// The page after the patient agreed to a request (PROFILE-01C): the name
/// comes from the account, and the patient names the circle for themself
/// with the same chips as their own circle («رعايتي», «صحتي», «دائرتي» or a
/// typed name). Only they see that name; the others see «دائرة» and the
/// patient's name. The birth date and city come from the account; an account
/// made before onboarding asked for them is asked here.
/// Needs a [CreateCircleCubit] of the approved flow above it.
class ApprovedCircleBasicsScreen extends StatefulWidget {
  const ApprovedCircleBasicsScreen({super.key});

  @override
  State<ApprovedCircleBasicsScreen> createState() => _ApprovedBasicsState();
}

class _ApprovedBasicsState extends State<ApprovedCircleBasicsScreen>
    with CreateCircleNameState<ApprovedCircleBasicsScreen> {
  @override
  Widget build(BuildContext context) {
    final CreateCircleCubit cubit = context.read<CreateCircleCubit>();
    return CircleBasicsScaffold(
      onCreate: () => create(cubit),
      children: (BuildContext context, CreateCircleState state) => <Widget>[
        StepHeader(
          title: context.tr('circles.approved_title'),
          onBack: context.canPop()
              ? () => context.pop()
              : () => context.go(Routes.notifications),
        ),
        const SizedBox(height: AppSpacing.xl),
        AccountNameField(state: state, onRetry: cubit.loadAccount),
        const SizedBox(height: AppSpacing.xl),
        CircleNameChips(cubit: cubit, state: state, customName: customName),
        const SizedBox(height: AppSpacing.sm),
        InsetText.note(context.tr('circles.name_hint')),
        CircleBasicsFields(cubit: cubit, state: state, topGap: AppSpacing.lg),
        CircleBasicsError(state: state),
      ],
    );
  }
}

/// The patient's name, read from the account and not editable ("من حسابك").
/// It shows a spinner while the names load, and a retry link when they fail.
class AccountNameField extends StatelessWidget {
  const AccountNameField({
    super.key,
    required this.state,
    required this.onRetry,
  });

  final CreateCircleState state;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final Widget content = switch (state.accountLoad) {
      AccountLoad.loaded || AccountLoad.notNeeded => Text(
        state.fullName ?? '',
        style: Theme.of(context).textTheme.bodyLarge,
      ),
      AccountLoad.loading => const Align(
        alignment: AlignmentDirectional.centerStart,
        child: SizedBox(
          width: AppSpacing.space5,
          height: AppSpacing.space5,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      AccountLoad.failed => AccountLoadFailed(
        messageKey: 'circles.name_failed',
        onRetry: onRetry,
      ),
    };
    return ReadOnlyField(
      label: context.tr('circles.name'),
      note: context.tr('circles.from_account'),
      child: content,
    );
  }
}

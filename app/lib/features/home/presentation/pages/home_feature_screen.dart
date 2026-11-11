import 'dart:async';

import 'package:app/core/feedback/app_toast.dart';
import 'package:app/core/l10n/arabic_counts.dart';
import 'package:app/core/media/private_photo_repository.dart';
import 'package:app/core/navigation/routers.dart';
import 'package:app/core/services/calendar_sync.dart';
import 'package:app/core/services/phone_notifications.dart';
import 'package:app/core/services/push_registration.dart';
import 'package:app/core/services/reminders/dose_reminders.dart';
import 'package:app/core/services/signed_out.dart';
import 'package:app/features/circles/presentation/cubit/inbox_cubit.dart';
import 'package:app/features/home/domain/entities/home_entity.dart';
import 'package:app/features/home/presentation/controllers/clinical_data_loader.dart';
import 'package:app/features/home/presentation/controllers/notification_tap_handler.dart';
import 'package:app/features/home/presentation/controllers/reminder_sync.dart';
import 'package:app/features/home/presentation/cubit/home_cubit.dart';
import 'package:app/features/home/presentation/cubit/home_state.dart';
import 'package:app/features/home/presentation/widgets/home_add_sheet.dart';
import 'package:app/features/home/presentation/widgets/home_body.dart';
import 'package:app/features/home/presentation/widgets/home_widget.dart';
import 'package:app/features/shell/app_shell.dart';
import 'package:app/features/shell/widgets/app_top_bar.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

/// The shell host of the four tabs: the bars, the circle switcher and what
/// the home data decides (sign-in ended, onboarding, no circle).
///
/// It only wires. The phone's side lives in small controllers: the data of
/// the shown circle ([ClinicalDataLoader]), the reminders and calendar
/// ([ReminderSync]) and the taps on a reminder ([NotificationTapHandler]).
class HomeFeatureScreen extends StatefulWidget {
  const HomeFeatureScreen({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  State<HomeFeatureScreen> createState() => _HomeFeatureScreenState();
}

class _HomeFeatureScreenState extends State<HomeFeatureScreen>
    with WidgetsBindingObserver {
  late final ClinicalDataLoader _clinical;
  late final ReminderSync _reminders;
  late final NotificationTapHandler _taps;
  late int _lastTabIndex;
  String? _loadedCircleId;

  /// Whether this phone's push token was asked for in this sign-in.
  bool _pushStarted = false;

  @override
  void initState() {
    super.initState();
    _lastTabIndex = widget.navigationShell.currentIndex;
    _clinical = ClinicalDataLoader(
      medications: context.read(),
      measurementPlans: context.read(),
      appointments: context.read(),
      measurementTasks: context.read(),
      measurementReadings: context.read(),
      occurrences: context.read(),
      prayers: context.read(),
    );
    _reminders = ReminderSync(
      GetIt.I<DoseReminders>(),
      GetIt.I<CalendarSync>(),
    );
    _taps = NotificationTapHandler(
      GetIt.I<PhoneNotifications>(),
      GetIt.I<DoseReminders>(),
      isReady: () => context.read<HomeCubit>().state.status == HomeStatus.ready,
      openToday: _openToday,
      openInbox: _openInbox,
      onSnoozed: _showSnoozed,
    );
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didUpdateWidget(covariant HomeFeatureScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final int tab = widget.navigationShell.currentIndex;
    if (tab != _lastTabIndex) {
      _clinical.tabChanged(
        _lastTabIndex,
        tab,
        context.read<HomeCubit>().state.selectedCircle,
      );
      _lastTabIndex = tab;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _taps.dispose();
    _clinical.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    // A circle member may have changed their photo on another phone while
    // this app was away. The home refresh below then reads every photo fresh.
    GetIt.I<PrivatePhotoRepository>().invalidateCache();
    // The page stays as it is while the data loads again in the background.
    unawaited(context.read<HomeCubit>().refresh());
    unawaited(context.read<InboxCubit>().load());
    _reminders.refresh();
    final CareCircleSummary? circle = context
        .read<HomeCubit>()
        .state
        .selectedCircle;
    if (circle != null) _clinical.load(circle, quiet: true);
  }

  /// A tapped reminder shows «اليوم» of its circle.
  void _openToday(String? circleId) {
    if (!mounted) return;
    if (circleId != null) {
      unawaited(context.read<HomeCubit>().selectCircle(circleId));
    }
    context.go(Routes.today);
  }

  /// A tapped push about an invitation or a request: its page.
  void _openInbox() {
    if (!mounted) return;
    unawaited(context.push(Routes.notifications));
  }

  /// Says when a reminder put off from its notification comes again.
  void _showSnoozed() {
    if (!mounted) return;
    AppToast.showText(
      ScaffoldMessenger.of(context),
      context.tr(
        'reminders.snoozed',
        args: <String>[afterDuration(context, notificationSnooze.inMinutes)],
      ),
    );
  }

  /// Opens the notifications and counts again when the person comes back,
  /// because an answer there changes what is left.
  Future<void> _openNotifications(BuildContext context) async {
    final InboxCubit inbox = context.read<InboxCubit>();
    await context.push<void>(Routes.notifications);
    if (!inbox.isClosed) unawaited(inbox.load());
  }

  void _onState(BuildContext context, HomeState state) {
    final HomeEntity? data = state.data;
    if (state.status == HomeStatus.ready && data != null) {
      _reminders.onHome(data);
      if (!_pushStarted) {
        // Circle updates from the server need the phone's push token. With
        // the free Apple account iOS gives none, and nothing happens.
        _pushStarted = true;
        unawaited(GetIt.I<PushRegistration>().start());
      }
      _taps.onReady();
    }
    if (state.status == HomeStatus.signIn) {
      // The sign-in ended: nothing stays for a person who is not signed in.
      unawaited(forgetSignedOutPerson());
      context.go(Routes.auth);
    } else if (state.status == HomeStatus.onboarding) {
      context.go(Routes.onboarding);
    } else if (state.status == HomeStatus.ready && state.messageKey != null) {
      AppToast.show(context, state.messageKey!, kind: ToastKind.error);
    }
    final CareCircleSummary? selected = state.selectedCircle;
    if (state.status == HomeStatus.ready &&
        selected != null &&
        selected.id != _loadedCircleId) {
      _loadedCircleId = selected.id;
      _clinical.load(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<HomeCubit>();
    return BlocConsumer<HomeCubit, HomeState>(
      listener: _onState,
      builder: (context, state) => AppShell(
        navigationShell: widget.navigationShell,
        topBar: AppTopBar(
          displayName: state.data?.displayName,
          avatarCode: state.data?.avatarCode,
          onPhotoSaved: cubit.refresh,
          circles: HomeWidget(
            state: state,
            onSelected: cubit.selectCircle,
            onAddCircle: state.status == HomeStatus.ready
                ? () => context.push(Routes.addCircle)
                : null,
          ),
          // A person with no circle yet can still have a request to answer.
          needsReply: context.select<InboxCubit, int>(
            (InboxCubit inbox) => inbox.state.inbox.needsReply,
          ),
          onNotifications: state.status == HomeStatus.ready
              ? () => _openNotifications(context)
              : null,
        ),
        onAdd: state.selectedCircle?.canManageMedications ?? false
            ? () => showHomeAddSheet(context, circleId: state.selectedCircleId!)
            : null,
        body: HomeBody(
          state: state,
          tabs: widget.navigationShell,
          onRetry: cubit.load,
          onCreateCircle: () => context.push(Routes.addCircle),
        ),
      ),
    );
  }
}

import 'dart:async';

import 'package:app/core/navigation/routers.dart';
import 'package:app/features/appointments/presentation/cubit/appointments_cubit.dart';
import 'package:app/core/services/phone_notifications.dart';
import 'package:app/core/services/push_registration.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/layout/content_switcher.dart';
import 'package:app/features/circles/presentation/cubit/inbox_cubit.dart';
import 'package:app/features/home/domain/entities/home_entity.dart';
import 'package:app/features/home/presentation/cubit/home_cubit.dart';
import 'package:app/features/home/presentation/cubit/home_state.dart';
import 'package:app/features/home/presentation/widgets/home_add_sheet.dart';
import 'package:app/features/home/presentation/widgets/home_widget.dart';
import 'package:app/features/medications/domain/dose_reminders.dart';
import 'package:app/features/medications/presentation/cubit/medication_occurrences_cubit.dart';
import 'package:app/features/medications/presentation/cubit/medications_cubit.dart';
import 'package:app/features/medications/presentation/widgets/medication_skeletons.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_plans_cubit.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_readings_cubit.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_tasks_cubit.dart';
import 'package:app/features/prayer_times/presentation/cubit/prayer_times_cubit.dart';
import 'package:app/features/shell/app_shell.dart';
import 'package:app/features/shell/widgets/app_top_bar.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

/// Displays the home feature screen UI.
class HomeFeatureScreen extends StatefulWidget {
  const HomeFeatureScreen({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  State<HomeFeatureScreen> createState() => _HomeFeatureScreenState();
}

class _HomeFeatureScreenState extends State<HomeFeatureScreen>
    with WidgetsBindingObserver {
  String? _loadedCircleId;
  Timer? _midnight;
  late int _lastTabIndex;

  /// The reminders at the dose times of every circle, set on the phone.
  final DoseReminders _reminders = GetIt.I<DoseReminders>();
  final PhoneNotifications _phone = GetIt.I<PhoneNotifications>();
  StreamSubscription<String>? _taps;

  /// The circles the reminders were last set for, so choosing another
  /// circle does not read them all again.
  List<CareCircleSummary>? _remindedCircles;

  /// A reminder tapped before the home data was ready.
  String? _pendingTap;

  /// Whether this phone's push token was asked for in this sign-in.
  bool _pushStarted = false;

  @override
  void initState() {
    super.initState();
    _lastTabIndex = widget.navigationShell.currentIndex;
    WidgetsBinding.instance.addObserver(this);
    _pendingTap = _phone.takeLaunchTap();
    _taps = _phone.taps.listen(_onTap);
  }

  @override
  void didUpdateWidget(covariant HomeFeatureScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final currentTabIndex = widget.navigationShell.currentIndex;
    if (_lastTabIndex != currentTabIndex && currentTabIndex == 2) {
      final circleId = context.read<HomeCubit>().state.selectedCircleId;
      if (circleId != null) {
        unawaited(context.read<MedicationsCubit>().load(circleId));
      }
    }
    if (_lastTabIndex == 3 && currentTabIndex == 0) {
      final circleId = context.read<HomeCubit>().state.selectedCircleId;
      if (circleId != null) {
        unawaited(
          context.read<PrayerTimesCubit>().load(circleId, refresh: true),
        );
      }
    }
    _lastTabIndex = currentTabIndex;
  }

  @override
  void dispose() {
    _midnight?.cancel();
    unawaited(_taps?.cancel());
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _onTap(String payload) {
    if (!mounted) return;
    if (context.read<HomeCubit>().state.status == HomeStatus.ready) {
      _openTap(payload);
    } else {
      _pendingTap = payload;
    }
  }

  /// A dose reminder opens «اليوم» of its circle, where the dose is marked;
  /// the note to open the app opens «اليوم» as it is.
  void _openTap(String payload) {
    _pendingTap = null;
    if (payload.startsWith(doseReminderPayload)) {
      unawaited(
        context.read<HomeCubit>().selectCircle(
          payload.substring(doseReminderPayload.length),
        ),
      );
    }
    context.go(Routes.today);
  }

  /// Sets the dose reminders for the person's circles when the list changes.
  void _remind(HomeEntity data) {
    if (listEquals(_remindedCircles, data.circles)) return;
    _remindedCircles = data.circles;
    unawaited(
      _reminders.sync(<ReminderCircle>[
        for (final CareCircleSummary circle in data.circles)
          ReminderCircle(id: circle.id, name: circle.name),
      ]),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // The page stays as it is while the data loads again in the background.
    if (state == AppLifecycleState.resumed) {
      unawaited(context.read<HomeCubit>().refresh());
      unawaited(context.read<InboxCubit>().load());
      // The next week of reminders, and none for a dose marked meanwhile.
      unawaited(_reminders.refresh());
      final String? circleId = context.read<HomeCubit>().state.selectedCircleId;
      if (circleId != null) _loadClinicalData(circleId);
    }
  }

  /// Opens the notifications and counts again when the person comes back,
  /// because an answer there changes what is left.
  Future<void> _openNotifications(BuildContext context) async {
    final InboxCubit inbox = context.read<InboxCubit>();
    await context.push<void>(Routes.notifications);
    if (!inbox.isClosed) inbox.load();
  }

  void _onState(BuildContext context, HomeState state) {
    final HomeEntity? data = state.data;
    if (state.status == HomeStatus.ready && data != null) {
      _remind(data);
      if (!_pushStarted) {
        // Circle updates from the server need the phone's push token. With
        // the free Apple account iOS gives none, and nothing happens.
        _pushStarted = true;
        unawaited(GetIt.I<PushRegistration>().start());
      }
      final String? tap = _pendingTap;
      if (tap != null) _openTap(tap);
    }
    if (state.status == HomeStatus.signIn) {
      // The sign-in ended: no reminders for a person who is not signed in.
      unawaited(_reminders.clear());
      context.go(Routes.auth);
    } else if (state.status == HomeStatus.onboarding) {
      context.go(Routes.onboarding);
    } else if (state.status == HomeStatus.ready && state.messageKey != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.tr(state.messageKey!))));
    }
    if (state.status == HomeStatus.ready &&
        state.selectedCircleId != null &&
        state.selectedCircleId != _loadedCircleId) {
      _loadedCircleId = state.selectedCircleId;
      _loadClinicalData(state.selectedCircleId!);
    }
  }

  void _loadClinicalData(String circleId) {
    final riyadhNow = DateTime.now().toUtc().add(const Duration(hours: 3));
    final DateTime today = DateTime.utc(
      riyadhNow.year,
      riyadhNow.month,
      riyadhNow.day,
    );
    unawaited(context.read<MedicationsCubit>().load(circleId));
    unawaited(context.read<MeasurementPlansCubit>().load(circleId));
    unawaited(context.read<AppointmentsCubit>().load(circleId));
    unawaited(context.read<MeasurementTasksCubit>().load(circleId, today));
    unawaited(
      context.read<MeasurementReadingsCubit>().load(circleId, today, today),
    );
    unawaited(
      context.read<MedicationOccurrencesCubit>().load(
        circleId,
        today.subtract(const Duration(days: 1)),
        today.add(const Duration(days: 30)),
      ),
    );
    unawaited(context.read<PrayerTimesCubit>().load(circleId));
    _midnight?.cancel();
    final now = riyadhNow;
    final next = DateTime.utc(now.year, now.month, now.day + 1);
    _midnight = Timer(next.difference(now), () {
      if (mounted) _loadClinicalData(circleId);
    });
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
        onAdd: state.selectedCircleId == null
            ? null
            : state.data!.circles
                  .firstWhere((circle) => circle.id == state.selectedCircleId)
                  .canManageMedications
            ? () => showHomeAddSheet(
                context,
                circleId: state.selectedCircleId!,
                onMedicationSaved: () {
                  if (mounted) _loadClinicalData(state.selectedCircleId!);
                },
                onMeasurementSaved: () {
                  if (mounted) _loadClinicalData(state.selectedCircleId!);
                },
                onAppointmentSaved: () {
                  if (mounted) _loadClinicalData(state.selectedCircleId!);
                },
                onReadingSaved: () {
                  if (mounted) _loadClinicalData(state.selectedCircleId!);
                },
              )
            : null,
        body: ContentSwitcher(
          stateKey: state.status,
          child: _body(state, cubit),
        ),
      ),
    );
  }

  Widget _body(HomeState state, HomeCubit cubit) {
    if (state.status == HomeStatus.loading) {
      // The app opens on «اليوم», so the first load looks like it.
      return const TodaySkeleton();
    }
    if (state.status == HomeStatus.failure) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(context.tr(state.messageKey!), textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.lg),
              FilledButton(
                onPressed: cubit.load,
                child: Text(context.tr('auth.retry')),
              ),
            ],
          ),
        ),
      );
    }
    if (state.status != HomeStatus.ready) return const SizedBox.shrink();
    if (state.data!.circles.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(context.tr('home.no_circles'), textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.lg),
              FilledButton(
                onPressed: () => context.push(Routes.addCircle),
                child: Text(context.tr('home.create_circle')),
              ),
            ],
          ),
        ),
      );
    }
    return widget.navigationShell;
  }
}

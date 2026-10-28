import 'dart:async';

import 'package:app/core/navigation/routers.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/widgets/loading_widget.dart';
import 'package:app/features/circles/presentation/cubit/inbox_cubit.dart';
import 'package:app/features/home/presentation/cubit/home_cubit.dart';
import 'package:app/features/home/presentation/cubit/home_state.dart';
import 'package:app/features/home/presentation/widgets/home_widget.dart';
import 'package:app/features/home/presentation/widgets/home_add_sheet.dart';
import 'package:app/features/medications/presentation/cubit/medication_occurrences_cubit.dart';
import 'package:app/features/medications/presentation/cubit/medications_cubit.dart';
import 'package:app/features/shell/app_shell.dart';
import 'package:app/features/shell/widgets/app_top_bar.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class HomeFeatureScreen extends StatefulWidget {
  const HomeFeatureScreen({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  State<HomeFeatureScreen> createState() => _HomeFeatureScreenState();
}

class _HomeFeatureScreenState extends State<HomeFeatureScreen>
    with WidgetsBindingObserver {
  String? _loadedCircleId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // The page stays as it is while the data loads again in the background.
    if (state == AppLifecycleState.resumed) {
      unawaited(context.read<HomeCubit>().refresh());
      unawaited(context.read<InboxCubit>().load());
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
    if (state.status == HomeStatus.signIn) {
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
    final DateTime today = DateUtils.dateOnly(DateTime.now());
    unawaited(context.read<MedicationsCubit>().load(circleId));
    unawaited(
      context.read<MedicationOccurrencesCubit>().load(circleId, today, today),
    );
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
          circles: HomeWidget(state: state, onSelected: cubit.selectCircle),
          onAddCircle: state.status == HomeStatus.ready
              ? () => context.push(Routes.addCircle)
              : null,
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
              )
            : null,
        body: _body(state, cubit),
      ),
    );
  }

  Widget _body(HomeState state, HomeCubit cubit) {
    if (state.status == HomeStatus.loading) return const LoadingWidget();
    if (state.status == HomeStatus.failure) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
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
          padding: const EdgeInsets.all(AppSpacing.xl),
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

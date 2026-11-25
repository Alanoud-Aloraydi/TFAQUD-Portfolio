import 'package:app/core/widgets/layout/refresh_scope.dart';
import 'package:app/features/home/presentation/cubit/home_cubit.dart';
import 'package:app/features/home/presentation/cubit/home_shell_lifecycle.dart';
import 'package:app/features/home/presentation/cubit/home_shell_wiring.dart';
import 'package:app/features/home/presentation/cubit/home_state_reactor.dart';
import 'package:app/features/home/presentation/widgets/home_shell_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// The shell host of the four tabs: the bars, the circle switcher and what
/// the home data decides (sign-in ended, onboarding, no circle).
///
/// It only wires. The phone's side lives in small controllers: the data of
/// the shown circle (`ClinicalDataLoader`), the reminders and calendar
/// (`ReminderSync`) and the taps on a reminder (`NotificationTapHandler`).
class HomeFeatureScreen extends StatefulWidget {
  const HomeFeatureScreen({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  State<HomeFeatureScreen> createState() => _HomeFeatureScreenState();
}

class _HomeFeatureScreenState extends State<HomeFeatureScreen>
    with WidgetsBindingObserver, HomeResumeRefresh<HomeFeatureScreen> {
  @override
  late final HomeStateReactor reactor;

  @override
  void initState() {
    super.initState();
    reactor = createHomeStateReactor(
      context,
      widget.navigationShell.currentIndex,
    );
  }

  @override
  void didUpdateWidget(covariant HomeFeatureScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    syncTab(context, reactor, widget.navigationShell.currentIndex);
  }

  @override
  void dispose() {
    reactor.dispose();
    super.dispose();
  }

  /// What every main tab does when pulled down from its top.
  Future<void> _refresh() => refreshNow(context, reactor);

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<HomeCubit>();
    return RefreshScope(
      onRefresh: _refresh,
      child: BlocConsumer<HomeCubit, HomeState>(
        listener: reactor.onState,
        builder: (context, state) =>
            homeShellView(context, state, cubit, widget.navigationShell),
      ),
    );
  }
}

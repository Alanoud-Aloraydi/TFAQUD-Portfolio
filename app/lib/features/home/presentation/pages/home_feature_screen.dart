import 'package:app/features/home/presentation/controllers/home_shell_lifecycle.dart';
import 'package:app/features/home/presentation/controllers/home_shell_wiring.dart';
import 'package:app/features/home/presentation/controllers/home_state_reactor.dart';
import 'package:app/features/home/presentation/cubit/home_cubit.dart';
import 'package:app/features/home/presentation/cubit/home_state.dart';
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
    with WidgetsBindingObserver {
  late final HomeStateReactor _reactor;

  @override
  void initState() {
    super.initState();
    _reactor = createHomeStateReactor(
      context,
      widget.navigationShell.currentIndex,
    );
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didUpdateWidget(covariant HomeFeatureScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    syncTab(context, _reactor, widget.navigationShell.currentIndex);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _reactor.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    refreshOnResume(context, _reactor);
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<HomeCubit>();
    return BlocConsumer<HomeCubit, HomeState>(
      listener: _reactor.onState,
      builder: (context, state) =>
          homeShellView(context, state, cubit, widget.navigationShell),
    );
  }
}

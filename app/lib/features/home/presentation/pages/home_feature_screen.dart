import 'package:app/core/navigation/routers.dart';
import 'package:app/core/widgets/loading_widget.dart';
import 'package:app/features/home/presentation/cubit/home_cubit.dart';
import 'package:app/features/home/presentation/cubit/home_state.dart';
import 'package:app/features/home/presentation/widgets/home_widget.dart';
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
      context.read<HomeCubit>().refresh();
    }
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
        ),
        body: _body(state, cubit),
      ),
    );
  }

  Widget _body(HomeState state, HomeCubit cubit) {
    if (state.status == HomeStatus.loading) return const LoadingWidget();
    if (state.status == HomeStatus.failure) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(context.tr(state.messageKey!), textAlign: TextAlign.center),
              const SizedBox(height: 16),
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
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                context.tr('home.no_circles'),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
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

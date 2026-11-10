import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/layout/content_switcher.dart';
import 'package:app/features/home/presentation/cubit/home_state.dart';
import 'package:app/features/medications/presentation/widgets/medication_skeletons.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// What the home shell shows under its bars for the home [state]: the
/// «اليوم» skeleton while loading, a message with a retry when the data
/// could not be read, a way to create the first circle when there is none,
/// and otherwise the tab pages ([tabs]).
class HomeBody extends StatelessWidget {
  const HomeBody({
    super.key,
    required this.state,
    required this.tabs,
    required this.onRetry,
    required this.onCreateCircle,
  });

  final HomeState state;
  final Widget tabs;
  final VoidCallback onRetry;
  final VoidCallback onCreateCircle;

  @override
  Widget build(BuildContext context) =>
      ContentSwitcher(stateKey: state.status, child: _content(context));

  Widget _content(BuildContext context) {
    switch (state.status) {
      case HomeStatus.loading:
        // The app opens on «اليوم», so the first load looks like it.
        return const TodaySkeleton();
      case HomeStatus.failure:
        return _Notice(
          message: context.tr(state.messageKey ?? 'error.unknown'),
          actionLabel: context.tr('auth.retry'),
          onAction: onRetry,
        );
      case HomeStatus.ready:
        if (state.data!.circles.isEmpty) {
          return _Notice(
            message: context.tr('home.no_circles'),
            actionLabel: context.tr('home.create_circle'),
            onAction: onCreateCircle,
          );
        }
        return tabs;
      case HomeStatus.signIn:
      case HomeStatus.onboarding:
        // The router is already leaving this page.
        return const SizedBox.shrink();
    }
  }
}

/// A centered message with one button under it.
class _Notice extends StatelessWidget {
  const _Notice({
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.lg),
          FilledButton(onPressed: onAction, child: Text(actionLabel)),
        ],
      ),
    ),
  );
}

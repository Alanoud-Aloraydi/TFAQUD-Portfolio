import 'package:app/core/widgets/task_viewer_scope.dart';
import 'package:app/features/home/domain/entities/home_entity.dart';
import 'package:app/features/home/presentation/cubit/home_cubit.dart';
import 'package:app/features/home/presentation/cubit/home_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Builds a tab page for the circle the home cubit selected, and rebuilds it
/// from scratch (a new key) when another circle is chosen. Nothing while no
/// circle is selected. Puts the signed-in account and their place in the
/// circle ([TaskViewerScope]) above the page, so a task's buttons can tell
/// whether the task is theirs to answer.
class SelectedCircleBuilder extends StatelessWidget {
  const SelectedCircleBuilder({super.key, required this.builder});

  final Widget Function(BuildContext context, CareCircleSummary circle) builder;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<HomeCubit, HomeState, _Shown?>(
      selector: (state) {
        final CareCircleSummary? circle = state.data?.circles
            .where((circle) => circle.id == state.selectedCircleId)
            .firstOrNull;
        final String? accountId = state.data?.accountId;
        if (circle == null || accountId == null) return null;
        return (circle: circle, accountId: accountId);
      },
      builder: (context, shown) {
        if (shown == null) return const SizedBox.shrink();
        return KeyedSubtree(
          key: ValueKey(shown.circle.id),
          child: TaskViewerScope(
            accountId: shown.accountId,
            isPatient: shown.circle.isPatient,
            child: builder(context, shown.circle),
          ),
        );
      },
    );
  }
}

/// The circle on screen and who is looking at it.
typedef _Shown = ({CareCircleSummary circle, String accountId});

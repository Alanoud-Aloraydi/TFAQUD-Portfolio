import 'package:app/app/router/routers.dart';
import 'package:app/core/widgets/navigation/glass_segmented_control.dart';
import 'package:app/features/circles/presentation/cubit/inbox_cubit.dart';
import 'package:app/features/home/presentation/cubit/home_cubit.dart';
import 'package:app/features/home/presentation/cubit/home_shell_actions.dart';
import 'package:app/features/home/presentation/cubit/home_state_reactor.dart';
import 'package:app/features/home/presentation/widgets/home_add_sheet.dart';
import 'package:app/features/home/presentation/widgets/home_body.dart';
import 'package:app/features/home/presentation/widgets/home_widget.dart';
import 'package:app/features/shell/presentation/widgets/app_shell.dart';
import 'package:app/features/shell/presentation/widgets/app_top_bar.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// The shell with its top bar, the add button and the body of the tabs.
Widget homeShellView(
  BuildContext context,
  HomeState state,
  HomeCubit cubit,
  StatefulNavigationShell navigationShell,
) {
  return AppShell(
    navigationShell: navigationShell,
    topBar: AppTopBar(
      displayName: state.data?.displayName,
      avatarCode: state.data?.avatarCode,
      onPhotoSaved: cubit.refresh,
      circles: HomeWidget(
        state: state,
        onSelected: cubit.selectCircle,
        onAddCircle: state.status == HomeStatus.ready
            ? () => openAddCircle(context, state.data?.circles.length ?? 0)
            : null,
      ),
      // A person with no circle yet can still have a request to answer.
      needsReply: context.select<InboxCubit, int>(
        (InboxCubit inbox) => inbox.state.inbox.needsReply,
      ),
      onNotifications: state.status == HomeStatus.ready
          ? () => openNotifications(context)
          : null,
    ),
    onAdd: state.selectedCircle?.canRecord ?? false
        ? () => showHomeAddSheet(context, circle: state.selectedCircle!)
        : null,
    body: HomeBody(
      state: state,
      tabs: navigationShell,
      onRetry: cubit.load,
      onCreateCircle: () => context.push(Routes.addCircle),
    ),
  );
}

/// The three kinds of care that «الخطة» and «السجل» split their pages by.
/// The order is the order of the segments and of the pages.
enum HomeCategory { medications, measurements, appointments }

/// Remembers which [HomeCategory] a tab page shows, for the page's
/// [HomeCategoryControl] and its pages (`category.index` is the page).
mixin HomeCategorySelection<T extends StatefulWidget> on State<T> {
  HomeCategory category = HomeCategory.medications;

  /// Shows [value]; the same one again does nothing.
  void selectCategory(HomeCategory value) {
    if (value != category) setState(() => category = value);
  }
}

/// Shared category selector for home composition tabs. The counts are shown
/// beside the labels unless [showCounts] is false.
class HomeCategoryControl extends StatelessWidget {
  const HomeCategoryControl({
    super.key,
    required this.selected,
    required this.onChanged,
    required this.counts,
    this.showCounts = true,
  });

  final HomeCategory selected;
  final ValueChanged<HomeCategory> onChanged;

  /// How many of each kind there are.
  final Map<HomeCategory, int> counts;
  final bool showCounts;

  @override
  Widget build(BuildContext context) => GlassSegmentedControl<HomeCategory>(
    segments: <HomeCategory, String>{
      for (final HomeCategory value in HomeCategory.values)
        value: context.tr('home_category.${value.name}'),
    },
    selected: selected,
    onChanged: onChanged,
    counts: showCounts ? counts : null,
  );
}

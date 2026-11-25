import 'package:app/app/router/routers.dart';
import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/layout/content_switcher.dart';
import 'package:app/core/widgets/navigation/glass_capsule_button.dart';
import 'package:app/core/widgets/navigation/glass_segmented_control.dart';
import 'package:app/features/circles/presentation/cubit/inbox_cubit.dart';
import 'package:app/features/home/domain/entities/home_entity.dart';
import 'package:app/features/home/presentation/cubit/home_cubit.dart';
import 'package:app/features/home/presentation/cubit/home_shell_actions.dart';
import 'package:app/features/home/presentation/cubit/home_state_reactor.dart';
import 'package:app/features/home/presentation/widgets/circle_switcher_capsule.dart';
import 'package:app/features/home/presentation/widgets/home_add_sheet.dart';
import 'package:app/features/medications/presentation/widgets/today_medication_attention_section.dart';
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
        return HomeNotice(
          message: context.tr(state.messageKey ?? 'error.unknown'),
          actionLabel: context.tr('auth.retry'),
          onAction: onRetry,
        );
      case HomeStatus.ready:
        if (state.data!.circles.isEmpty) {
          return HomeNotice(
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
class HomeNotice extends StatelessWidget {
  const HomeNotice({
    super.key,
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

/// The circle switcher in the middle of the top bar (design system TopBar):
/// a glass capsule with the selected circle's name and a down chevron. A tap
/// grows it into a glass menu, in place, with every circle (a check mark on
/// the current one) and «إضافة دائرة». The choice is shared by all the home tabs. With no circle
/// yet, the capsule is «إضافة دائرة» itself.
class HomeWidget extends StatefulWidget {
  const HomeWidget({
    super.key,
    required this.state,
    required this.onSelected,
    this.onAddCircle,
  });

  final HomeState state;
  final ValueChanged<String> onSelected;

  /// Null hides «إضافة دائرة» (for example while the home data loads).
  final VoidCallback? onAddCircle;

  @override
  State<HomeWidget> createState() => _HomeWidgetState();
}

class _HomeWidgetState extends State<HomeWidget> {
  /// While the menu is open the capsule is hidden: the menu's glass grew
  /// out of it, so there is one piece of glass, as in iOS.
  bool _menuOpen = false;

  HomeState get state => widget.state;
  ValueChanged<String> get onSelected => widget.onSelected;
  VoidCallback? get onAddCircle => widget.onAddCircle;

  @override
  Widget build(BuildContext context) {
    final List<CareCircleSummary> circles =
        state.data?.circles ?? const <CareCircleSummary>[];
    if (circles.isEmpty) return AddCircleCapsule(onPressed: onAddCircle);
    final CareCircleSummary selected = selectedCircleOf(
      circles,
      state.selectedCircleId,
    );
    return Opacity(
      opacity: _menuOpen ? 0 : 1,
      child: CircleSwitcherCapsule(
        selected: selected,
        onPressed: () => chooseCircle(
          context,
          circles: circles,
          selected: selected,
          onSelected: onSelected,
          onAddCircle: onAddCircle,
          setMenuOpen: (open) => setState(() => _menuOpen = open),
          isMounted: () => mounted,
        ),
      ),
    );
  }
}

/// The circle with [selectedId], or the first one when none matches.
CareCircleSummary selectedCircleOf(
  List<CareCircleSummary> circles,
  String? selectedId,
) {
  CareCircleSummary selected = circles.first;
  for (final CareCircleSummary circle in circles) {
    if (circle.id == selectedId) selected = circle;
  }
  return selected;
}

/// «إضافة دائرة» as the capsule itself, for an account with no circle yet.
/// Nothing is drawn while [onPressed] is null (the home data is loading).
class AddCircleCapsule extends StatelessWidget {
  const AddCircleCapsule({super.key, required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    if (onPressed == null) return const SizedBox.shrink();
    final String add = context.tr('topbar.add_circle');
    return GlassCapsuleButton(
      label: add,
      semanticLabel: add,
      icon: ActionIcons.plus,
      onPressed: onPressed,
    );
  }
}

import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/widgets/navigation/glass_capsule_button.dart';
import 'package:app/features/home/domain/entities/home_entity.dart';
import 'package:app/features/home/presentation/cubit/home_state_reactor.dart';
import 'package:app/features/home/presentation/widgets/circle_switcher_capsule.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

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

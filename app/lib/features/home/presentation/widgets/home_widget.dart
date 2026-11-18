import 'package:app/features/home/domain/entities/home_entity.dart';
import 'package:app/features/home/presentation/cubit/home_state.dart';
import 'package:app/features/home/presentation/widgets/add_circle_capsule.dart';
import 'package:app/features/home/presentation/widgets/choose_circle.dart';
import 'package:app/features/home/presentation/widgets/circle_switcher_capsule.dart';
import 'package:app/features/home/presentation/widgets/selected_circle_of.dart';
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

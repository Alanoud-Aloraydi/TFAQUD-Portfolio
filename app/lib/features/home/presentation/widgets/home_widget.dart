import 'package:app/core/constants/app_colors.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/widgets/glass.dart';
import 'package:app/core/widgets/glass_menu.dart';
import 'package:app/features/home/domain/entities/home_entity.dart';
import 'package:app/features/home/presentation/cubit/home_state.dart';
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

  /// What the menu returns for «إضافة دائرة». Circle ids never look like it.
  static const String _addCircle = '\u0000add-circle';

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
    if (circles.isEmpty) {
      if (onAddCircle == null) return const SizedBox.shrink();
      final String add = context.tr('topbar.add_circle');
      return GlassCapsuleButton(
        label: add,
        semanticLabel: add,
        icon: Icons.add,
        onPressed: onAddCircle,
      );
    }
    CareCircleSummary selected = circles.first;
    for (final CareCircleSummary circle in circles) {
      if (circle.id == state.selectedCircleId) selected = circle;
    }
    final String name = selected.name;
    final String selectedId = selected.id;
    return Opacity(
      opacity: _menuOpen ? 0 : 1,
      child: GlassCapsuleButton(
      label: name,
      semanticLabel: context.tr(
        'topbar.switch_circle',
        args: <String>[selected.name],
      ),
      icon: Icons.keyboard_arrow_down,
      onPressed: () => _choose(context, circles, selectedId, name),
      ),
    );
  }

  Future<void> _choose(
    BuildContext context,
    List<CareCircleSummary> circles,
    String selectedId,
    String name,
  ) async {
    setState(() => _menuOpen = true);
    final String? picked = await showGlassMenu<String>(
      anchorContext: context,
      semanticLabel: context.tr('topbar.circles_title'),
      // The capsule's own content, which blurs away as the glass grows.
      anchorContent: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Flexible(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          const Icon(
            Icons.keyboard_arrow_down,
            size: AppSizes.iconSmall,
            color: AppColors.ink,
          ),
        ],
      ),
      sections: <List<GlassMenuItem<String>>>[
        <GlassMenuItem<String>>[
          for (final CareCircleSummary circle in circles)
            GlassMenuItem<String>(
              value: circle.id,
              label: circle.name,
              selected: circle.id == selectedId,
            ),
        ],
        if (onAddCircle != null)
          <GlassMenuItem<String>>[
            GlassMenuItem<String>(
              value: HomeWidget._addCircle,
              label: context.tr('topbar.add_circle'),
              icon: Icons.add,
            ),
          ],
      ],
    );
    if (!mounted) return;
    setState(() => _menuOpen = false);
    if (picked == null) return;
    if (picked == HomeWidget._addCircle) {
      onAddCircle?.call();
    } else if (picked != selectedId) {
      onSelected(picked);
    }
  }
}

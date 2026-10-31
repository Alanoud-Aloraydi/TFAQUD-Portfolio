import 'package:app/core/theme/app_text_theme.dart';
import 'package:app/core/widgets/glass.dart';
import 'package:app/features/home/domain/entities/home_entity.dart';
import 'package:app/features/home/presentation/cubit/home_state.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// The circle switcher in the middle of the top bar (design system TopBar):
/// a glass capsule with the selected circle's name and a down chevron. A tap
/// opens an iOS action sheet with every circle (the current one in bold) and
/// «إضافة دائرة». The choice is shared by all the home tabs. With no circle
/// yet, the capsule is «إضافة دائرة» itself.
class HomeWidget extends StatelessWidget {
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

  /// What the sheet returns for «إضافة دائرة». Circle ids never look like it.
  static const String _addCircle = '\u0000add-circle';

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
    return GlassCapsuleButton(
      label: selected.name,
      semanticLabel: context.tr(
        'topbar.switch_circle',
        args: <String>[selected.name],
      ),
      icon: Icons.keyboard_arrow_down,
      onPressed: () => _choose(context, circles, selected.id),
    );
  }

  Future<void> _choose(
    BuildContext context,
    List<CareCircleSummary> circles,
    String selectedId,
  ) async {
    const TextStyle style = TextStyle(fontFamily: AppTextTheme.fontFamily);
    final String? picked = await showCupertinoModalPopup<String>(
      context: context,
      builder: (BuildContext sheetContext) => CupertinoActionSheet(
        title: Text(sheetContext.tr('topbar.circles_title'), style: style),
        actions: <Widget>[
          for (final CareCircleSummary circle in circles)
            CupertinoActionSheetAction(
              isDefaultAction: circle.id == selectedId,
              onPressed: () => Navigator.pop(sheetContext, circle.id),
              child: Text(circle.name, style: style),
            ),
          if (onAddCircle != null)
            CupertinoActionSheetAction(
              onPressed: () => Navigator.pop(sheetContext, _addCircle),
              child: Text(sheetContext.tr('topbar.add_circle'), style: style),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(sheetContext),
          child: Text(sheetContext.tr('common.cancel'), style: style),
        ),
      ),
    );
    if (picked == null || !context.mounted) return;
    if (picked == _addCircle) {
      onAddCircle?.call();
    } else if (picked != selectedId) {
      onSelected(picked);
    }
  }
}

import 'package:app/core/widgets/navigation/glass_capsule_button.dart';
import 'package:app/core/widgets/overlays/glass_menu_item.dart';
import 'package:flutter/cupertino.dart';

/// A record filter: a glass capsule that opens an anchored glass menu, the
/// same on «الأدوية», «المواعيد» and «القياسات».
class WhiteFilterMenu<T extends Object> extends StatefulWidget {
  const WhiteFilterMenu({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  final Map<T, String> options;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  State<WhiteFilterMenu<T>> createState() => _WhiteFilterMenuState<T>();
}

class _WhiteFilterMenuState<T extends Object>
    extends State<WhiteFilterMenu<T>> {
  bool _menuOpen = false;

  /// The chosen option's words. A choice that is no longer among the
  /// options (its month read away, the person who recorded it gone) falls
  /// back to the first, which is «الكل»: a filter is never worth a crash.
  String get _label =>
      widget.options[widget.selected] ?? widget.options.values.first;

  @override
  Widget build(BuildContext context) => Align(
    alignment: AlignmentDirectional.centerStart,
    child: Builder(
      // Hidden while its menu is open: one piece of glass.
      builder: (anchorContext) => Opacity(
        opacity: _menuOpen ? 0 : 1,
        child: GlassCapsuleButton(
          label: _label,
          semanticLabel: _label,
          icon: CupertinoIcons.slider_horizontal_3,
          onPressed: () => _openGlass(anchorContext),
        ),
      ),
    ),
  );

  Future<void> _openGlass(BuildContext anchorContext) async {
    setState(() => _menuOpen = true);
    final value = await showGlassMenu<T>(
      anchorContext: anchorContext,
      semanticLabel: _label,
      anchorContent: Text(_label),
      sections: [
        [
          for (final option in widget.options.entries)
            GlassMenuItem<T>(
              value: option.key,
              label: option.value,
              selected: option.key == widget.selected,
            ),
        ],
      ],
    );
    if (!mounted) return;
    setState(() => _menuOpen = false);
    if (value != null) widget.onChanged(value);
  }
}

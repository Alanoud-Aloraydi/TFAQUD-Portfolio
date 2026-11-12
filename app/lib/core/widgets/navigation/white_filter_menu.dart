import 'package:app/core/widgets/navigation/glass.dart';
import 'package:app/core/widgets/overlays/glass_menu.dart';
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

  @override
  Widget build(BuildContext context) => Align(
    alignment: AlignmentDirectional.centerStart,
    child: Builder(
      // Hidden while its menu is open: one piece of glass.
      builder: (anchorContext) => Opacity(
        opacity: _menuOpen ? 0 : 1,
        child: GlassCapsuleButton(
          label: widget.options[widget.selected]!,
          semanticLabel: widget.options[widget.selected]!,
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
      semanticLabel: widget.options[widget.selected]!,
      anchorContent: Text(widget.options[widget.selected]!),
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

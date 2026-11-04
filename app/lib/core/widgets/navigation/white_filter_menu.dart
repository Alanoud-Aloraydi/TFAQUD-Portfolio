import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_radius.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/navigation/glass.dart';
import 'package:app/core/widgets/overlays/glass_menu.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Opens a record filter menu with an optional anchored glass presentation.
class WhiteFilterMenu<T extends Object> extends StatefulWidget {
  const WhiteFilterMenu({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
    this.glass = false,
  });

  final Map<T, String> options;
  final T selected;
  final ValueChanged<T> onChanged;
  final bool glass;

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
      builder: (anchorContext) => widget.glass
          ? Opacity(
              opacity: _menuOpen ? 0 : 1,
              child: GlassCapsuleButton(
                label: widget.options[widget.selected]!,
                semanticLabel: widget.options[widget.selected]!,
                icon: CupertinoIcons.slider_horizontal_3,
                onPressed: () => _openGlass(anchorContext),
              ),
            )
          : _whiteButton(anchorContext),
    ),
  );

  Widget _whiteButton(BuildContext context) => OutlinedButton.icon(
    onPressed: () => _open(context),
    style: OutlinedButton.styleFrom(
      backgroundColor: AppSemanticColors.surfaceContent,
      foregroundColor: AppSemanticColors.textPrimary,
      side: const BorderSide(color: AppSemanticColors.borderSubtle),
      minimumSize: const Size(0, AppSizes.touch),
      shape: const StadiumBorder(),
    ),
    icon: const Icon(CupertinoIcons.slider_horizontal_3),
    label: Text(widget.options[widget.selected]!),
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

  Future<void> _open(BuildContext context) async {
    final value = await showModalBottomSheet<T>(
      context: context,
      useRootNavigator: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: AppSemanticColors.surfaceContent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.l)),
      ),
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final option in widget.options.entries)
              ListTile(
                title: Text(option.value),
                trailing: option.key == widget.selected
                    ? const Icon(CupertinoIcons.check_mark)
                    : null,
                onTap: () => Navigator.of(sheetContext).pop(option.key),
              ),
          ],
        ),
      ),
    );
    if (value != null && context.mounted) widget.onChanged(value);
  }
}

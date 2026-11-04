import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_radius.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Opens the same white selection menu for record filters in each domain.
class WhiteFilterMenu<T extends Object> extends StatelessWidget {
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
  Widget build(BuildContext context) => Align(
    alignment: AlignmentDirectional.centerStart,
    child: OutlinedButton.icon(
      onPressed: () => _open(context),
      style: OutlinedButton.styleFrom(
        backgroundColor: AppSemanticColors.surfaceContent,
        foregroundColor: AppSemanticColors.textPrimary,
        side: const BorderSide(color: AppSemanticColors.borderSubtle),
        minimumSize: const Size(0, AppSizes.touch),
        shape: const StadiumBorder(),
      ),
      icon: const Icon(CupertinoIcons.slider_horizontal_3),
      label: Text(options[selected]!),
    ),
  );

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
            for (final option in options.entries)
              ListTile(
                title: Text(option.value),
                trailing: option.key == selected
                    ? const Icon(CupertinoIcons.check_mark)
                    : null,
                onTap: () => Navigator.of(sheetContext).pop(option.key),
              ),
          ],
        ),
      ),
    );
    if (value != null && context.mounted) onChanged(value);
  }
}
